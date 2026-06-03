import * as fs from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import { pathToFileURL } from 'node:url';
import { getModelName, formatModelName, getProviderLabel } from '../../stdin.js';
import { getOutputSpeed } from '../../speed-tracker.js';
import { git as gitColor, gitBranch as gitBranchColor, warning as warningColor, critical as criticalColor, label, model as modelColor, project as projectColor, effort as effortColor, red, green, yellow, dim, custom as customColor, brightGreen } from '../colors.js';
import { t } from '../../i18n/index.js';
import { renderCostEstimate } from './cost.js';
import { normalizeAddedDirs, sanitize as sanitizeDisplayText, basenameOf, truncateBasename, MAX_RENDERED_ADDED_DIRS } from './added-dirs.js';
function hyperlink(uri, text) {
    const esc = '\x1b';
    const st = '\\';
    return `${esc}]8;;${uri}${esc}${st}${text}${esc}]8;;${esc}${st}`;
}
function getFileHref(filePath) {
    try {
        return pathToFileURL(path.resolve(filePath)).toString();
    }
    catch {
        return null;
    }
}
function resolvePathWithinCwd(cwd, candidatePath) {
    const resolvedCwd = path.resolve(cwd);
    const resolvedPath = path.resolve(cwd, candidatePath);
    const relative = path.relative(resolvedCwd, resolvedPath);
    if (relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative))) {
        return resolvedPath;
    }
    return null;
}
function safeHyperlink(uri, text) {
    if (!uri) {
        return text;
    }
    const sanitizedUri = sanitizeDisplayText(uri);
    try {
        const parsed = new URL(sanitizedUri);
        if (parsed.protocol !== 'https:' && parsed.protocol !== 'file:') {
            return text;
        }
        return hyperlink(parsed.toString(), text);
    }
    catch {
        return text;
    }
}
export function renderProjectLine(ctx) {
    const display = ctx.config?.display;
    const colors = ctx.config?.colors;
    const parts = [];
    // OS info + customLine (username)
    const platform = os.platform() === 'darwin' ? 'MacOS' : os.platform() === 'win32' ? 'Windows' : 'Linux';
    const osRelease = os.release();
    const osInfo = `${platform} ${osRelease}`;
    const customLine = display?.customLine;
    if (customLine) {
        const resolvedCustomLine = customLine.replace(/\{username\}/g, os.userInfo().username);
        parts.push(customColor(`${osInfo} │ ${resolvedCustomLine}`, colors));
    }
    else {
        parts.push(label(osInfo, colors));
    }
    let projectPart = null;
    if (display?.showProject !== false && ctx.stdin.cwd) {
        const homeDir = os.homedir();
        let displayPath = ctx.stdin.cwd;
        if (displayPath.startsWith(homeDir)) {
            displayPath = '~' + displayPath.slice(homeDir.length);
        }
        const segments = displayPath.split(/[/\\]/).filter(Boolean);
        const pathLevels = ctx.config?.pathLevels ?? 1;
        const projectPath = sanitizeDisplayText(segments.length > 0 ? segments.slice(-pathLevels).join('/') : '/');
        const coloredProject = projectColor(projectPath, colors);
        projectPart = safeHyperlink(getFileHref(ctx.stdin.cwd), coloredProject);
    }
    let addedDirsPart = null;
    const addedDirs = normalizeAddedDirs(ctx.stdin.workspace?.added_dirs);
    const addedDirsLayout = display?.addedDirsLayout ?? 'inline';
    if (display?.showAddedDirs !== false && addedDirsLayout === 'inline' && addedDirs.length > 0) {
        const visible = addedDirs.slice(0, MAX_RENDERED_ADDED_DIRS);
        const overflow = addedDirs.length - visible.length;
        const rendered = visible.map((dir) => {
            const name = truncateBasename(sanitizeDisplayText(basenameOf(dir)));
            const text = dim(`+${name}`);
            return safeHyperlink(getFileHref(dir), text);
        });
        if (overflow > 0) {
            rendered.push(dim(`+${overflow} more`));
        }
        addedDirsPart = rendered.join(' ');
    }
    let gitPart = '';
    const gitConfig = ctx.config?.gitStatus;
    const showGit = gitConfig?.enabled ?? true;
    const branchOverflow = gitConfig?.branchOverflow ?? 'truncate';
    if (showGit && ctx.gitStatus) {
        const branchText = sanitizeDisplayText(ctx.gitStatus.branch + ((gitConfig?.showDirty ?? true) && ctx.gitStatus.isDirty ? '*' : ''));
        const coloredBranch = gitBranchColor(branchText, colors);
        const linkedBranch = safeHyperlink(ctx.gitStatus.branchUrl, coloredBranch);
        const gitInner = [linkedBranch];
        if (gitConfig?.showAheadBehind) {
            if (ctx.gitStatus.ahead > 0) {
                gitInner.push(formatAheadCount(ctx.gitStatus.ahead, gitConfig, colors));
            }
            if (ctx.gitStatus.behind > 0)
                gitInner.push(gitBranchColor(`↓${ctx.gitStatus.behind}`, colors));
        }
        if (gitConfig?.showFileStats && ctx.gitStatus.fileStats) {
            const { modified, added, deleted, untracked } = ctx.gitStatus.fileStats;
            const statParts = [];
            if (modified > 0)
                statParts.push(yellow(`!${modified}`));
            if (added > 0)
                statParts.push(brightGreen(`+${added}`));
            if (deleted > 0)
                statParts.push(red(`-${deleted}`));
            if (untracked > 0)
                statParts.push(dim(`?${untracked}`));
            if (statParts.length > 0) {
                gitInner.push(statParts.join(' '));
            }
        }
        gitPart = `${gitColor('git:(', colors)}${gitInner.join(' ')}${gitColor(')', colors)}`;
    }
    const projectWithDirs = projectPart && addedDirsPart
        ? `${projectPart} ${addedDirsPart}`
        : projectPart ?? addedDirsPart;
    if (projectWithDirs && gitPart) {
        if (branchOverflow === 'wrap') {
            parts.push(projectWithDirs);
            parts.push(gitPart);
        }
        else {
            parts.push(`${projectWithDirs} ${gitPart}`);
        }
    }
    else if (projectWithDirs) {
        parts.push(projectWithDirs);
    }
    else if (gitPart) {
        parts.push(gitPart);
    }
    if (display?.showSessionName && ctx.transcript.sessionName) {
        parts.push(label(ctx.transcript.sessionName, colors));
    }
    if (display?.showClaudeCodeVersion && ctx.claudeCodeVersion) {
        parts.push(label(`CC v${ctx.claudeCodeVersion}`, colors));
    }
    if (ctx.extraLabel) {
        parts.push(label(ctx.extraLabel, colors));
    }
    // Model after project info
    if (display?.showModel !== false) {
        const model = formatModelName(getModelName(ctx.stdin), ctx.config?.display?.modelFormat, ctx.config?.display?.modelOverride);
        const providerLabel = getProviderLabel(ctx.stdin);
        const modelQualifier = providerLabel ?? undefined;
        const modelDisplay = modelQualifier ? `${model} | ${modelQualifier}` : model;
        const modelBadge = modelColor(`[${modelDisplay}]`, colors);
        if (ctx.effortLevel) {
            parts.push(`${modelBadge} ${effortColor(ctx.effortLevel, colors)}`);
        }
        else {
            parts.push(modelBadge);
        }
    }
    if (display?.showDuration !== false && ctx.sessionDuration) {
        parts.push(label(ctx.sessionDuration, colors));
    }
    // Cost moved to identity line (line 2)
    if (display?.showSpeed) {
        const speed = getOutputSpeed(ctx.stdin);
        if (speed !== null) {
            parts.push(label(`${t('format.out')}: ${speed.toFixed(1)} ${t('format.tokPerSec')}`, colors));
        }
    }
    if (parts.length === 0) {
        return null;
    }
    return parts.join(' \u2502 ');
}
function formatAheadCount(ahead, gitConfig, colors) {
    const value = `↑${ahead}`;
    const criticalThreshold = gitConfig?.pushCriticalThreshold ?? 0;
    const warningThreshold = gitConfig?.pushWarningThreshold ?? 0;
    if (criticalThreshold > 0 && ahead >= criticalThreshold) {
        return criticalColor(value, colors);
    }
    if (warningThreshold > 0 && ahead >= warningThreshold) {
        return warningColor(value, colors);
    }
    return gitBranchColor(value, colors);
}
export function renderGitFilesLine(ctx, terminalWidth = null) {
    const gitConfig = ctx.config?.gitStatus;
    if (!(gitConfig?.showFileStats ?? false))
        return null;
    if (!ctx.gitStatus?.fileStats)
        return null;
    const { trackedFiles, untracked } = ctx.gitStatus.fileStats;
    if (trackedFiles.length === 0 && untracked === 0)
        return null;
    if (terminalWidth !== null && terminalWidth < 60)
        return null;
    const cwd = ctx.stdin.cwd;
    const sorted = [...trackedFiles].sort((a, b) => {
        try {
            const aPath = cwd ? resolvePathWithinCwd(cwd, a.fullPath) : null;
            const bPath = cwd ? resolvePathWithinCwd(cwd, b.fullPath) : null;
            const aMtime = aPath ? fs.statSync(aPath).mtimeMs : 0;
            const bMtime = bPath ? fs.statSync(bPath).mtimeMs : 0;
            return bMtime - aMtime;
        }
        catch {
            return 0;
        }
    });
    const shown = sorted.slice(0, 6);
    const overflow = sorted.length - shown.length;
    const statParts = [];
    for (const trackedFile of shown) {
        const prefix = trackedFile.type === 'added' ? green('+') : trackedFile.type === 'deleted' ? red('-') : yellow('~');
        const safeBasename = sanitizeDisplayText(trackedFile.basename);
        const coloredName = trackedFile.type === 'added'
            ? green(safeBasename)
            : trackedFile.type === 'deleted'
                ? red(safeBasename)
                : yellow(safeBasename);
        const resolvedPath = cwd ? resolvePathWithinCwd(cwd, trackedFile.fullPath) : null;
        const linkedName = resolvedPath ? safeHyperlink(getFileHref(resolvedPath), coloredName) : coloredName;
        let entry = `${prefix}${linkedName}`;
        if (trackedFile.lineDiff) {
            const diffParts = [];
            if (trackedFile.lineDiff.added > 0)
                diffParts.push(green(`+${trackedFile.lineDiff.added}`));
            if (trackedFile.lineDiff.deleted > 0)
                diffParts.push(red(`-${trackedFile.lineDiff.deleted}`));
            if (diffParts.length > 0) {
                entry += dim(`(${diffParts.join(' ')})`);
            }
        }
        statParts.push(entry);
    }
    if (overflow > 0)
        statParts.push(dim(`+${overflow} more`));
    if (untracked > 0)
        statParts.push(dim(`?${untracked}`));
    return statParts.join('  ');
}
//# sourceMappingURL=project.js.map