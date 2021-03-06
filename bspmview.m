function S = bspmview(ol, ul)
% BSPMVIEW Program for viewing fMRI statistical maps
%
%   USAGE: S = bspmview(ol*, ul*)       *optional inputs
%
% Requires that Statistical Parametric Mapping (SPM; Wellcome Trust Centre
% for Neuroimaging; www.fil.ion.ucl.ac.uk/spm/) be in your MATLAB search
% path. It has only been tested on SPM8/SPM12 operating in MATLAB 2014b. It
% requires a number of supporting utility functions and data files that
% should have been included in the distribution of BSPMVIEW. When BSPMVIEW
% is launched, it will look for these files in a folder called
% "supportfiles" that should be contained in the same folder as BSPMVIEW.
% 
% _________________________________________________________________________
%  INPUTS
%	ol: filename for statistical image to overlay
%	ul: filename for anatomical image to use as underlay
%
% _________________________________________________________________________
%  EXAMPLES
%   >> bspmview('spmT_0001.img', 'T1.nii')   % overlay on 'T1.nii'
%   >> bspmview('spmT_0001.img')   % overlay on default underlay
%   >> bspmview                    % open dialogue for selecting overlay
%   >> S = bspmview;     % returns struct 'S' containing GUI obj handles
%   
% _________________________________________________________________________
%  CREDITS
% 	This software heavily relies on functions contained within the SPM
% 	software, and is essentially an attempt to translate some of it into a
% 	simpler and more user-friendly format. In addition, this software was
% 	inspired by and in some cases uses code from two other statistical
% 	image viewers: XJVIEW.m by Xu Cui, Jian Li, and Xiaowei Song
% 	(http://www.alivelearn.net/xjview8/developers/), and FIVE.m by Aaron P.
% 	Schultz (http://mrtools.mgh.harvard.edu/index.php/Main_Page). This also
% 	employs some of the functionality of PEAK_NII.m by Donald McLaren
% 	(http://www.nmr.mgh.harvard.edu/~mclaren/ftp/Utilities_DGM/). Moreover,
% 	several contributions to the MATLAB File Exchange
% 	(http://www.mathworks.com/matlabcentral/fileexchange/) are called by
% 	the code. These are included in the "supporting files" folder that should 
%   have been included in the distribution of the main BSPMVIEW function.
%   The documentation of the supporting functions contains further
%   information about the source and respective copyright holders. 
% 

% ------ Copyright (C) Bob Spunt, California Institute of Technology ------
%   Email:    bobspunt@gmail.com
%	Created:  2014-09-27
%   GitHub:   https://github.com/spunt/bspmview
%   Version:  20150308
%
%   This program is free software: you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation, either version 3 of the License, or (at
%   your option) any later version.
%       This program is distributed in the hope that it will be useful, but
%   WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%   General Public License for more details.
%       You should have received a copy of the GNU General Public License
%   along with this program.  If not, see: http://www.gnu.org/licenses/.
% _________________________________________________________________________
global version
version='20150308'; 

% | CHECK FOR SPM FOLDER
% | =======================================================================
spmdir = fileparts(which('spm'));
if isempty(spmdir)
    printmsg('SPM is not on your path. This may not work...', 'WARNING');
else
    addpath(fullfile(spmdir,'matlabbatch'));
    addpath(fullfile(spmdir,'config'));
end

% | CHECK FOR SUPPORTFILES AND SPM FOLDER
% | =======================================================================
supportdir = fullfile(fileparts(mfilename('fullpath')), 'supportfiles');
if ~exist(supportdir, 'dir'), printmsg('The folder "supportfiles" was not found', 'ERROR'); return; end
addpath(supportdir);

% | CHECK INPUTS
% | =======================================================================
if nargin < 1 
    ol = uigetvol('Select an Image File for Overlay', 0);
    if isempty(ol), disp('Must select an overlay!'); return; end
else
    if iscell(ol), ol = char(ol); end
end
if nargin < 2
    ul = fullfile(supportdir, 'IIT_MeanT1_2x2x2.nii');
else
    if iscell(ul), ul = char(ul); end
end
global prevsect 
prevsect = ul;

% | INITIALIZE FIGURE, SPM REGISTRY, & ORTHVIEWS
% | =======================================================================
printmsg(sprintf('Started %s', nicetime), sprintf('BSPMVIEW v.%s', version));
try
    S = put_figure(ol, ul); shg;
catch err
    save_error(err);
    rethrow(err)
end

% =========================================================================
% *
% * SUBFUNCTIONS
% *
% =========================================================================

% | GUI DEFAULTS
% =========================================================================
function pos    = default_positions 
    screensize      = get(0, 'ScreenSize');
    pos.ss          = screensize(3:4);
    pos.gui         = [pos.ss(1)*.5 pos.ss(2)*.20 pos.ss(2)*.55 pos.ss(2)*.5];
    pos.gui(3:4)    = pos.gui(3:4)*1.10; 
    pos.aspratio    = pos.gui(3)/pos.gui(4);
    if pos.gui(3) < 600, pos.gui(3) = 600; pos.gui(4) = pos.gui(3)*pos.aspratio; end
    guiss           = [pos.gui(3:4) pos.gui(3:4)]; 
    panepos         = getpositions(1, [12 1], .01, .01);
    pos.pane.upper  = panepos(2,3:end); 
    pos.pane.axes   = panepos(1,3:end).*guiss; 
function color  = default_colors(darktag)
    if nargin==0, darktag = 1; end
    if darktag
        color.fg        = [248/255 248/255 248/255];
        color.bg        = [20/255 23/255 24/255] * 2;
    else
        color.fg       = [20/255 23/255 24/255]; 
        color.bg       = [248/255 248/255 248/255] * .90;
    end
    color.border    = [023/255 024/255 020/255]*2;
    color.xhair     = [0.7020    0.8039    0.8902];
    color.panel     = [.01 .22 .34];
    color.blues     = brewermap(40, 'Blues'); 
function fonts  = default_fonts
    fonts.name      = 'Arial'; 
    fonts.sz1       = 24;
    fonts.sz2       = 18; 
    fonts.sz3       = 16; 
    fonts.sz4       = 14;
    fonts.sz5       = 13; 
    fonts.sz6       = 12;
function prop   = default_properties(varargin)
    global st
    prop.darkbg     = {'backg', st.color.bg, 'foreg', st.color.fg};
    prop.lightbg    = {'backg', st.color.fg, 'foreg', [0 0 0]};
    if ~isempty(varargin), prop.darkbg = [varargin{:} prop.darkbg]; prop.lightbg = [varargin{:} prop.lightbg]; end
%     prop.panel      = [prop.darkbg {'bordertype', 'line', 'titlepos', 'centertop', 'fontw', 'bold'}];
    prop.panel      = [prop.darkbg {'bordertype', 'none', 'titlepos', 'centertop', 'fontw', 'bold'}]; 
    prop.edit       = [prop.lightbg {'style', 'edit', 'horiz', 'center'}];
    prop.text       = [prop.darkbg {'style', 'text', 'horiz', 'center'}]; 
    prop.popup      = [prop.lightbg {'style', 'popup'}]; 
%     prop.slider     = [prop.darkbg {'style', 'slide', 'min', 1.0000e-20, 'max', 1, 'sliderstep', [1 5], 'value', st.ol.P}];
    prop.push       = [prop.darkbg {'style', 'push', 'horiz', 'center'}]; 
    prop.radio      = [prop.darkbg {'style', 'radio', 'horiz', 'center'}];
    prop.toggle     = [prop.darkbg {'style', 'toggle'}]; 
    prop.checkbox   = [prop.darkbg {'style', 'check'}]; 
    prop.listbox    = [prop.darkbg {'style', 'list'}]; 
function cmap   = default_colormaps(depth)
    if nargin==0, depth = 64; end
    cmap = []; 
    cmap{1,1}  = jet(depth);
    cmap{1,2}  = 'jet';
    cmap{2,1}  = hot(depth);
    cmap{2,2}  = 'hot';
    bmap1 = {'Blues' 'Greens' 'Greys' 'Oranges' 'Purples' 'Reds'};
    for i = 1:length(bmap1)
        tmp = brewermap(50, bmap1{i});
        cmap{2+i,1} = cmap_upsample(tmp(11:end,:), depth); 
        cmap{2+i,2} = sprintf('%s', bmap1{i});
    end
    tmp1 = brewermap(36, '*Blues'); 
    tmp2 = brewermap(36, 'Reds'); 
    cmap{end+1,1} = [tmp1(1:32,:); tmp2(5:36,:)]; 
    cmap{end,2} = 'Blues-Reds';
    bmap2 = {'Accent' 'Dark2' 'Paired' 'Pastel1' 'Pastel2' 'Set1' 'Set2' 'Set3'};
    bnum2 = [8 8 12 9 8 9 8 12];
    anchor = size(cmap,1); 
    for i = 1:length(bmap2)
        cmap{anchor+i,1} = cmap_upsample(brewermap(bnum2(i), bmap2{i}), depth); 
        cmap{anchor+i,2} = sprintf('%s (%d)', bmap2{i}, bnum2(i));
    end
function prefs  = default_preferences(initial)
    if nargin==0, initial = 0; end
    global st
    if ~isfield(st, 'preferences')
        def  = struct( ...
            'atlasname', 'AnatomyToolbox', ...
            'alphacorrect'  ,   .05, ...
            'separation',   20, ...
            'shape'     ,  'Sphere', ...
            'size'      ,   10, ...
            'surfshow'  ,   4, ...
            'surface'   ,   'Inflated', ...
            'shading'   ,   'Sulc', ...
            'nverts'    ,   40962, ...
            'round'     ,   false, ...
            'shadingmin', .1, ...
            'shadingmax', .7, ...
            'colorbar', true); 
         if initial, st.preferences = def; return; end
    else
        def = st.preferences; 
    end
    pos = get(st.fig, 'pos'); 
    w   = pos(3)*.65;
    opt             = {'L/R Medial/Lateral' 'L/R Lateral' 'L Medial/Lateral' 'R Medial/Lateral' 'L Lateral' 'R Lateral'};
    optmap          = [4 2 1.9 2.1 -1 1]; 
    opt             = [opt(optmap==def.surfshow) opt(optmap~=def.surfshow)]; 
    optmap          = [optmap(optmap==def.surfshow) optmap(optmap~=def.surfshow)]; 
    surftypeopt     = {'Inflated' 'Pial' 'White'}; 
    surftypeopt     = [surftypeopt(strcmpi(surftypeopt, def.surface)) surftypeopt(~strcmpi(surftypeopt, def.surface))]; 
    surftypeshade   = {'Sulc' 'Curv'};
    surftypeshade   = [surftypeshade(strcmpi(surftypeshade, def.shading)) surftypeshade(~strcmpi(surftypeshade, def.shading))]; 
    nvertopt        = [40962 642 2562 10242 163842]; 
    nvertopt        = [nvertopt(nvertopt==def.nverts) nvertopt(nvertopt~=def.nverts)]; 
    atlasopt        = {'AnatomyToolbox'                    ,...
                    'HarvardOxford-cort-maxprob-thr0'   ,...
                    'HarvardOxford-sub-maxprob-thr0'     ...
                    }; 
    atlasopt     = [atlasopt(strcmpi(atlasopt, def.atlasname)) atlasopt(~strcmpi(atlasopt, def.atlasname))];             
    [prefs, button] = settingsdlg(...
        'title'                     ,   'Settings', ...
        'WindowWidth'               ,   w,    ...
        'ControlWidth'              ,   w/2,    ...
        'separator'                 ,   'Thresholding', ...
        {'Corrected Alpha'; 'alphacorrect'}, def.alphacorrect, ...
        {'Peak Separation'; 'separation'},   def.separation, ...
        'separator'                 ,   'Anatomical Labeling', ...
        {'Name'; 'atlasname'}          , atlasopt, ...
        'separator'                 ,   'Surface Rendering', ...
        {'Surfaces to Render'; 'surfshow'}  , opt, ...
        {'Surface Type'; 'surface'}      ,   surftypeopt, ...
        {'Shading Type'; 'shading'}      ,   surftypeshade, ...
        {'N Vertices'; 'nverts'}    ,   num2cell(nvertopt), ...
        {'Shading Min'; 'shadingmin'},      def.shadingmin, ...
        {'Shading Max'; 'shadingmax'},      def.shadingmax, ...
        {'Add Color Bar'; 'colorbar'},      logical(def.colorbar), ...
        {'Round Values?'; 'round'}   ,      logical(def.round)); 
    if strcmpi(button, 'cancel'), return; else st.preferences = prefs; end
    if ~strcmpi(st.preferences.atlasname, def.atlasname)
        %% LABEL MAP
        atlas_vol = fullfile(st.supportpath, sprintf('%s_Atlas_Map.nii', st.preferences.atlasname)); 
        atlas_labels = fullfile(st.supportpath, sprintf('%s_Atlas_Labels.mat', st.preferences.atlasname)); 
        atlasvol = reslice_image(atlas_vol, st.ol.fname);
        atlasvol = single(round(atlasvol(:)))'; 
        load(atlas_labels);
        st.ol.atlaslabels = atlas; 
        st.ol.atlas0 = atlasvol;
        setvoxelinfo; 
    end
    st.preferences.surfshow = optmap(strcmpi(opt, st.preferences.surfshow)); 
    
% | GUI COMPONENTS
% =========================================================================
function S = put_figure(ol, ul)

    global st

    % | Check for open GUI, close if one is found
    delete(findobj(0, 'tag', 'bspmview')); 

    % | Setup new fig
    fonts   = default_fonts; 
    pos     = default_positions; 
    color   = default_colors; 
    S.hFig  = figure(...
            'Name', abridgepath(ol), ...
            'Units', 'pixels', ...
            'Position',pos.gui,...
            'Resize','off',...
            'Color',color.bg,...
            'ColorMap',gray(64),...
            'NumberTitle','off',...
            'DockControls','off',...
            'MenuBar','none',...
            'Tag', 'bspmview', ...
            'CloseRequestFcn', @cb_closegui, ...
            'DefaultTextColor',color.fg,...
            'DefaultTextInterpreter','none',...
            'DefaultTextFontName','Arial',...
            'DefaultTextFontSize',12,...
            'DefaultAxesColor',color.border,...
            'DefaultAxesXColor',color.border,...
            'DefaultAxesYColor',color.border,...
            'DefaultAxesZColor',color.border,...
            'DefaultAxesFontName','Arial',...
            'DefaultPatchFaceColor',color.fg,...
            'DefaultPatchEdgeColor',color.fg,...
            'DefaultSurfaceEdgeColor',color.fg,...
            'DefaultLineColor',color.border,...
            'DefaultUicontrolFontName',fonts.name,...
            'DefaultUicontrolFontSize',fonts.sz3,...
            'DefaultUicontrolInterruptible','on',...
            'Visible','off',...
            'Toolbar','none');
    uicontrol('Parent', S.hFig, 'Units', 'Normal', 'Style', 'Text', ...
    'pos', [0 0 1 .001], 'backg', color.blues(8,:));
    uicontrol('Parent', S.hFig, 'Units', 'Normal', 'Style', 'Text', ...
    'pos', [0 .001 .001 1], 'backg', color.blues(10,:));
    uicontrol('Parent', S.hFig, 'Units', 'Normal', 'Style', 'Text', ...
    'pos', [.999 .001 .001 .999], 'backg', color.blues(10,:));

    % | REGISTRY OBJECT (HREG)
    S.hReg = uipanel('Parent',S.hFig,'Units','Pixels','Position',pos.pane.axes,...
            'BorderType', 'none', 'BackgroundColor',color.bg);
    set(S.hReg, 'units', 'norm');
    bspm_orthviews('Reset');
    st          = struct( ...
                'fig',          S.hFig,...
                'figax',        S.hReg,...
                'guipath',      fileparts(mfilename('fullpath')),...
                'supportpath',  fullfile(fileparts(mfilename('fullpath')), 'supportfiles'),...
                'n',            0,...
                'bb',           [],...
                'callback',     {';'}, ...
                'Space',        eye(4),...
                'centre',       [],...
                'xhairs',       1,...
                'plugins',      {''},...
                'hld',          1,...
                'mode',         [],...
                'color',        color,...
                'pos',          pos,...
                'fonts',        fonts,...
                'direct',       '+/-',...
                'snap',         []);
    default_preferences(1);
    st.cmap     = default_colormaps(64); 
    st.vols     = cell(24,1);
    st.ol       = load_overlay(ol, .001, 5);
    bspm_XYZreg('InitReg',S.hReg,st.ol.M,st.ol.DIM,[0;0;0]); % initialize registry object
    st.ho = bspm_orthviews('Image', ul, [.025 .025 .95 .95]);
    bspm_orthviews('Register', S.hReg);
    bspm_orthviews('MaxBB');
    setposition_axes; 
    setxhaircolor;
    put_figmenu; 
    put_upperpane;
    put_lowerpane;
    put_axesxyz; 
    put_axesmenu;
    setthresh(st.ol.C0(3,:), find(strcmpi({'+', '-', '+/-'}, st.direct))); 
    setvoxelinfo;
    setcolormap;  
    setunits;
    setfontunits('points'); 
    check4design;  
    if nargout==1, S.handles = gethandles; end
function put_upperpane(varargin)
    global st
    cnamepos     = [.01 .15 .98 .85]; 
    prop         = default_properties('units', 'norm', 'fontu', 'norm', 'fonts', .55); 
    panelh       = uipanel('parent',st.fig, prop.panel{:}, 'pos', st.pos.pane.upper, 'tag', 'upperpanel'); 
    panelabel    = {{'Effect Direction' '+' '-' '+/-' 'Color Map' 'Color Max'}, {'Text' 'Radio' 'Radio' 'Radio' 'Popup' 'Edit'}}; 
    relwidth     = [3 1 1 2 3 2]; 
    tag          = {'label' 'direct' 'direct' 'direct' 'colormaplist' 'maxval'};  
    ph = buipanel(panelh, panelabel{1}, panelabel{2}, relwidth, 'paneltitle', '', 'panelposition', cnamepos, 'tag', tag, 'uicontrolsep', .01, 'marginsep', .025, 'panelfontsize', st.fonts.sz4, 'labelfontsize', st.fonts.sz4, 'editfontsize', st.fonts.sz5); 
    
    % | Check valid directions for contrast display
    allh    = findobj(st.fig, 'Tag', 'direct');
    allhstr = get(allh, 'String');
    if any(st.ol.null)
        opt = {'+' '-'}; 
        set(allh(strcmpi(allhstr, '+/-')), 'Value', 0, 'Enable', 'inactive', 'Visible', 'on');
        set(allh(strcmpi(allhstr, opt{st.ol.null})), 'Value', 0, 'Enable', 'inactive',  'Visible', 'on');
        set(allh(strcmpi(allhstr, opt{st.ol.null==0})), 'Value', 1, 'Enable', 'inactive');
    else
        set(allh(strcmpi(allhstr, '+/-')), 'value', 1, 'enable', 'inactive'); 
    end
 
    % | Set some values
    fs = get(ph.edit(2), 'fontsize'); 
    arrayset(ph.edit(2:4), 'fontsize', fs*1.25);
    arrayset(ph.edit(2:4), 'Callback', @cb_directmenu);
    set(ph.edit(1), 'FontSize', st.fonts.sz3); 
    set(ph.edit(6), 'callback', @cb_maxval);
    set(ph.edit(5), 'String', st.cmap(:,2), 'Value', 1, 'callback', @setcolormap);
    set(panelh, 'units', 'norm');
    drawnow;
function put_lowerpane(varargin)

    global st
    % | UNITS
    figpos  = get(st.fig, 'pos');
    axpos   = get(st.figax, 'pos');
    figw    = figpos(3);
    axw     = axpos(3); 

    % | PANEL
    [h,subaxpos] = gethandles_axes;
    lowpos = subaxpos(1,:);
    lowpos(1) = subaxpos(3, 1) + .01; 
    lowpos(3) = 1 - lowpos(1); 
    
    prop = default_properties('units', 'norm', 'fontn', 'arial', 'fonts', 19);  
    panelh = uipanel('parent', st.figax, prop.panel{:}, 'pos',lowpos, 'tag', 'lowerpanel');
    
    % | Create each subpanel 
    panepos         = getpositions(1, [1 4 4 1 1 4 4], .025, .025);
    panepos(:,1:2)  = [];
    panepos([1 5],:)    = []; 
    panename        = {'' '' '' '' ''};
    panelabel{1}    = {{'DF' 'Correction'}, {'Edit' 'Popup'}};  
    panelabel{2}    = {{'Extent' 'Thresh' 'P-Value'}, {'Edit' 'Edit' 'Edit'}}; 
    panelabel{3}    = {{'Thresholding Options'}, {'Text'}}; 
    panelabel{4}    = {{'Value' 'Coordinate' 'Cluster Size'}, {'Edit' 'Edit' 'Edit'}};
    panelabel{5}    = {{'Current Location'}, {'Edit'}}; 
    relwidth        = {[4 8] [3 4 5] [1] [3 5 3] [1]};
    relheight       = {[6 6] [6 6] [6 6] [6 6] [6 6]}; 
    tag             = {panelabel{1}{1}, panelabel{2}{1}, panelabel{3}{1}, {'voxval' 'xyz' 'clustersize'}, {'Location'}};  
    
    for i = 1:length(panename)
        ph{i} = buipanel(panelh, panelabel{i}{1}, panelabel{i}{2}, relwidth{i}, 'paneltitle', panename{i}, 'panelposition', panepos(i,:), 'tag', tag{i}, 'relheight', relheight{i}); 
    end

    % | Set some values
    set(ph{1}.edit(2), 'String', {'None' 'Voxel FWE' 'Cluster FWE'}, 'Value', 1, 'Callback', @cb_correct);  
    hndl = [ph{2}.edit; ph{1}.edit(1)]; 
    arrayset(hndl, 'Callback', @cb_updateoverlay); 
    Tdefvalues  = [st.ol.K st.ol.U st.ol.P st.ol.DF];
    Tstrform = {'%d' '%2.2f' '%2.3f' '%d'}; 
    for i = 1:length(Tdefvalues), set(hndl(i), 'str', sprintf(Tstrform{i}, Tdefvalues(i))); end
    arrayset(ph{4}.edit([1 3]), 'enable', 'inactive'); 
    set(ph{3}.edit, 'FontSize', st.fonts.sz2); 
    set(ph{4}.edit(2), 'callback', @cb_changexyz); 
    set(ph{5}.label, 'FontSize', st.fonts.sz2); 
    set(ph{5}.edit, 'enable', 'inactive', 'str', 'n/a'); 
    set(panelh, 'units', 'norm');
    drawnow;
function put_figmenu
    global st
    
    %% Main Menu
    S.menu1         = uimenu('Parent', st.fig, 'Label', 'bspmVIEW');
    S.appear        = uimenu(S.menu1, 'Label','Appearance'); 
    S.skin          = uimenu(S.appear, 'Label', 'Skin');
    S.changeskin(1) = uimenu(S.skin, 'Label', 'Dark', 'Checked', 'on', 'Callback', @cb_changeskin);
    S.changeskin(2) = uimenu(S.skin, 'Label', 'Light', 'Separator', 'on', 'Callback',@cb_changeskin);
    S.guisize       = uimenu(S.appear, 'Label','GUI Size','Separator', 'on'); 
    S.gui(1)        = uimenu(S.guisize, 'Label', 'Increase', 'Accelerator', 'i', 'Callback', @cb_changeguisize);
    S.gui(2)        = uimenu(S.guisize, 'Label', 'Decrease', 'Accelerator', 'd', 'Separator', 'on', 'Callback',@cb_changeguisize);
    S.fontsize      = uimenu(S.appear, 'Label','Font Size', 'Separator', 'on'); 
    S.font(1)       = uimenu(S.fontsize, 'Label', 'Increase', 'Accelerator', '=', 'Callback', @cb_changefontsize);
    S.font(2)       = uimenu(S.fontsize, 'Label', 'Decrease', 'Accelerator', '-', 'Separator', 'on', 'Callback',@cb_changefontsize);
    S.checkversion  = uimenu(S.menu1, 'Label', 'Check Version', 'Separator', 'on', 'Callback', @cb_checkversion); 
    S.opencode      = uimenu(S.menu1, 'Label','Open GUI M-File', 'Separator', 'on', 'Callback', @cb_opencode); 
    S.exit          = uimenu(S.menu1, 'Label', 'Exit', 'Separator', 'on', 'Callback', {@cb_closegui, st.fig});
    
    %% Make sure resize callbacks are registered one at a time
    set(S.gui, 'BusyAction', 'cancel', 'Interruptible', 'off'); 
    set(S.font, 'BusyAction', 'cancel', 'Interruptible', 'off');

    %% Load Menu
    S.load = uimenu(st.fig,'Label','Load', 'Separator', 'on');
    S.loadol = uimenu(S.load,'Label','Overlay Image', 'Accelerator', 'o', 'CallBack', @cb_loadol);
    S.loadul = uimenu(S.load,'Label','Underlay Image', 'Accelerator', 'u', 'Separator', 'on', 'CallBack', @cb_loadul);
    
    %% Save Menu
    S.save              = uimenu(st.fig,'Label','Save', 'Separator', 'on');
    S.saveintensity     = uimenu(S.save,'Label','Save as intensity image','CallBack', @cb_saveimg);
    S.savemask          = uimenu(S.save,'Label','Save as mask', 'Separator', 'on', 'CallBack', @cb_saveimg);
    S.saveroi           = uimenu(S.save,'Label','Save ROI at current location', 'Separator', 'on', 'CallBack', @cb_saveroi);
    S.savetable         = uimenu(S.save,'Label','Save Results Table', 'Separator', 'on', 'CallBack', @cb_savetable);
    
    %% Options Menu
    S.options       = uimenu(st.fig,'Label','Display', 'Separator', 'on');
    S.prefs         = uimenu(S.options, 'Label','Preferences', 'Accelerator', 'P', 'Callback', @cb_preferences); 
    S.report        = uimenu(S.options,'Label','Show Results Table', 'Accelerator', 't', 'Separator', 'on', 'CallBack', @cb_report);
    S.render        = uimenu(S.options,'Label','Show Surface Rendering',  'Accelerator', 'r', 'CallBack', @cb_render);
    S.crosshair     = uimenu(S.options,'Label','Toggle Crosshairs', 'Accelerator', 'c', 'Tag', 'Crosshairs', 'Checked', 'on', 'CallBack', @cb_crosshair);
    S.reversemap    = uimenu(S.options,'Label','Reverse Color Map', 'Tag', 'reversemap', 'Checked', 'off', 'CallBack', @cb_reversemap);   
    
    %% Web Menu
    S.web(1)        = uimenu(st.fig,'Label','Web', 'Separator', 'on');
    S.web(2)        = uimenu(S.web(1),'Label','bspmview GitHub repository', 'CallBack', {@cb_web, 'https://github.com/spunt/bspmview'});
    S.web(3)        = uimenu(S.web(1),'Label','SPM Extensions', 'CallBack', {@cb_web, 'http://www.fil.ion.ucl.ac.uk/spm/ext/'});
    S.web(4)        = uimenu(S.web(1),'Label','SPM Archives Search', 'CallBack', {@cb_web,'https://www.jiscmail.ac.uk/cgi-bin/webadmin?REPORT&z=4&1=spm&L=spm'});          
    S.web(5)        = uimenu(S.web(1),'Label','MR Tools Wiki', 'CallBack', {@cb_web, 'http://mrtools.mgh.harvard.edu/index.php/Main_Page'});
    S.web(6)        = uimenu(S.web(1),'Label','Peak_Nii', 'CallBack', {@cb_web, 'http://www.nitrc.org/projects/peak_nii'}); 
    S.web(7)        = uimenu(S.web(1),'Label','NeuroVault', 'Callback',{@cb_web, 'http://neurovault.org'}); 
    S.web(8)        = uimenu(S.web(1),'Label','Search Coordinates in Neurosynth', 'CallBack', @cb_neurosynth);      
function put_axesmenu
    [h,axpos]   = gethandles_axes;
    cmenu       = uicontextmenu;
    ctmax       = uimenu(cmenu, 'Label', 'Go to global max', 'callback', @cb_minmax, 'separator', 'off');
    ctclustmax  = uimenu(cmenu, 'Label', 'Go to cluster max', 'callback', @cb_clustminmax);
    ctns        = uimenu(cmenu, 'Label', 'Search Coordinates in Neurosynth',  'CallBack', @cb_neurosynth);  
    ctsavemap   = uimenu(cmenu, 'Label', 'Save cluster', 'callback', @cb_saveclust, 'separator', 'on');
    ctsavemask  = uimenu(cmenu, 'Label', 'Save cluster (binary mask)', 'callback', @cb_saveclust);
    ctsaveroi   = uimenu(cmenu, 'Label', 'Save ROI at Coordinates', 'callback', @cb_saveroi);
    ctrmcluster = uimenu(cmenu, 'Label', 'Hide cluster', 'callback', @cb_hideclust);
    ctsavergb   = uimenu(cmenu, 'Label', 'Save Screen Capture', 'callback', @cb_savergb, 'separator', 'on');
    ctxhair     = uimenu(cmenu, 'Label', 'Toggle Crosshairs', 'checked', 'on', 'Accelerator', 'c', 'Tag', 'Crosshairs', 'callback', @cb_crosshair, 'separator', 'on'); 
    for a = 1:3
        set(h.ax(a), 'uicontextmenu', cmenu); 
    end
    drawnow;
function put_axesxyz
    global st
    h = gethandles_axes;
    xyz = round(bspm_XYZreg('GetCoords',st.registry.hReg));
    xyzstr = num2str([-99; xyz]); 
    xyzstr(1,:) = [];
    set(h.ax, 'YAxislocation', 'right'); 
    axidx = [3 2 1]; 
    for a = 1:length(axidx)
        yh = get(h.ax(axidx(a)), 'YLabel'); 
        st.vols{1}.ax{axidx(a)}.xyz = yh; 
        if a==1
            set(yh, 'units', 'norm', 'fontunits', 'norm', 'fontsize', .075, ...
                'pos', [0 1 0], 'horiz', 'left', 'fontname', 'arial', ...
                'color', [1 1 1], 'string', xyzstr(a,:), 'rot', 0, 'tag', 'xyzlabel');
            set(yh, 'fontunits', 'points'); 
            fs = get(yh, 'fontsize');
        else
            set(yh, 'units', 'norm', 'fontsize', fs, ...
                'pos', [0 1 0], 'horiz', 'left', 'fontname', 'arial', ...
                'color', [1 1 1], 'string', xyzstr(a,:), 'rot', 0, 'tag', 'xyzlabel');
        end
    end
    drawnow;

% | GUI CALLBACKS
% =========================================================================
function cb_updateoverlay(varargin)
    global st
    T0  = getthresh;
    T   = T0;
    di  = strcmpi({'+' '-' '+/-'}, T.direct);
    if nargin > 0
        tag = get(varargin{1}, 'tag');
        switch tag
            case {'Thresh'}
                if T.df~=Inf, T.pval = bob_t2p(T.thresh, T.df); end
            case {'P-Value'}
                if T.df~=Inf, T.thresh = spm_invTcdf(1-T.pval, T.df); end
            case {'DF'}
                if ~any([T.pval T.df]==Inf)
                    T.thresh = spm_invTcdf(1-T.pval, T.df); 
                    T.pval = bob_t2p(T.thresh, T.df);
                end
            case {'Extent'}
                if sum(st.ol.C0(di,st.ol.C0(di,:)>=T.extent))==0
                    headsup('No clusters survived. Defaulting to largest cluster at this voxelwise threshold.');
                    T.extent = max(st.ol.C0(di,:));
                end
        end
    end
    [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
    C = st.ol.C0(di,:); 
    if sum(C(C>=T.extent))==0
        T0.thresh = st.ol.U; 
        setthreshinfo(T0);
        headsup('No voxels survived. Try a different threshold.'); 
        return
    end
    setthresh(C, find(di)); 
    setthreshinfo(T);
    drawnow;
function cb_loadol(varargin)
    global st
    fname = uigetvol('Select an Image File for Overlay', 0);
    if isempty(fname), disp('An overlay image was not selected.'); return; end
    T0  = getthresh;
    T   = T0; 
    di  = strcmpi({'+' '-' '+/-'}, T.direct); 
    st.ol = load_overlay(fname, T.pval, T.extent);
    setthresh(st.ol.C0(3,:), find(di));
    setthreshinfo; 
    setcolormap; 
    setposition_axes;
    check4design; 
    drawnow;
function cb_loadul(varargin)
    
    ul = uigetvol('Select an Image File for Underlay', 0);
    if isempty(ul), disp('An underlay image was not selected.'); return; end
    global st prevsect
    prevsect    = ul;
    h = gethandles_axes; 
    delete(h.ax);
    bspm_orthviews('Delete', st.ho);
    st.ho = bspm_orthviews('Image', ul, [.025 .025 .95 .95]);
    bspm_orthviews('MaxBB');
    bspm_orthviews('AddBlobs', st.ho, st.ol.XYZ, st.ol.Z, st.ol.M);
    bspm_orthviews('Register', st.registry.hReg);
    setposition_axes;
    setxhaircolor;
    put_axesxyz;
    put_axesmenu;
    h = findall(st.fig, 'Tag', 'Crosshairs'); 
    set(h,'Checked','on');
    bspm_orthviews('Xhairs','on') 
    drawnow;
function cb_clustminmax(varargin)
    global st
    str = get(findobj(st.fig, 'tag', 'clustersize'), 'string'); 
    if strcmp(str, 'n/a'), return; end
    [xyz, voxidx] = getnearestvoxel;
    clidx = spm_clusters(st.ol.XYZ);
    clidx = clidx==(clidx(voxidx)); 
    tmpXYZmm = st.ol.XYZmm(:,clidx); 
    if regexp(get(varargin{1}, 'label'), 'cluster max')
        centre = tmpXYZmm(:,st.ol.Z(clidx)==max(st.ol.Z(clidx)));
    elseif regexp(get(varargin{1}, 'label'), 'cluster min')
        centre = tmpXYZmm(:,st.ol.Z(clidx)==min(st.ol.Z(clidx)));
    end
    bspm_orthviews('reposition', centre);
    drawnow;
function cb_minmax(varargin)
    global st
    lab = get(varargin{1}, 'label');
    if regexp(lab, 'global max')
        centre = st.ol.XYZmm(:,st.ol.Z==max(st.ol.Z));
    elseif regexp(lab, 'global min')
        centre = st.ol.XYZmm(:,st.ol.Z==min(st.ol.Z)); 
    end
    bspm_orthviews('reposition', centre); 
    drawnow;
function cb_maxval(varargin)
    val = str2num(get(varargin{1}, 'string')); 
    bspm_orthviews('SetBlobsMax', 1, 1, val)
    drawnow;
function cb_changexyz(varargin)
    xyz = str2num(get(varargin{1}, 'string')); 
    bspm_orthviews('reposition', xyz');
    drawnow;
function cb_tablexyz(varargin)
    tabrow  = varargin{2}.Indices(1);
    tabdata = get(varargin{1}, 'data'); 
    xyz     = cell2mat(tabdata(tabrow,4:6)); 
    bspm_orthviews('reposition', xyz');
    drawnow;
function cb_directmenu(varargin)
    global st
    if ischar(varargin{1}), str = varargin{1}; 
    else str = get(varargin{1}, 'string'); end
    allh = findobj(st.fig, 'Tag', 'direct'); 
    allhstr = get(allh, 'String');
    set(allh(strcmp(allhstr, str)), 'Value', 1, 'Enable', 'inactive'); 
    set(allh(~strcmp(allhstr, str)), 'Value', 0, 'Enable', 'on');
    drawnow;
    T = getthresh;
    di = strcmpi({'+' '-' '+/-'}, T.direct);
    [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
    C = st.ol.C0(di,:);
    if sum(C>0)==0 
        headsup('Nothing survives at this threshold. Showing unthresholded image.');
        T.thresh = 0; 
        T.pval = bob_t2p(T.thresh, T.df);
        T.extent = 1; 
        [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
        C = st.ol.C0(di,:);
        setthreshinfo(T); 
    end
    setthreshinfo(T); 
    setthresh(C, find(di));
function cb_opencode(varargin)
    open(mfilename('fullpath'));
function cb_crosshair(varargin)
    global st
    state = get(varargin{1},'Checked');
    h = findall(st.fig, 'Tag', 'Crosshairs'); 
    if strcmpi(state,'on');
        bspm_orthviews('Xhairs','off')
        set(h,'Checked','off');
    end
    if strcmpi(state,'off');
        bspm_orthviews('Xhairs','on')
        set(h,'Checked','on');
    end
    drawnow;
function cb_saveimg(varargin)
    global st
    lab = get(varargin{1}, 'label');
    T = getthresh; 
    di = strcmpi({'+' '-' '+/-'}, T.direct); 
    clustidx = st.ol.C0(di,:);
    opt = [1 -1 1]; 
    outimg = st.ol.Y*opt(di);
    outhdr = st.ol.hdr;
    outimg(clustidx==0) = NaN;
    putmsg = 'Save intensity image as'; 
    outhdr.descrip = 'Thresholded Intensity Image'; 
    [p,n] = fileparts(outhdr.fname); 
    deffn = sprintf('%s/Thresh_%s.nii', p, n);  
    if regexp(lab, 'Save as mask')
        outimg(isnan(outimg))   = 0; 
        outimg(outimg~=0)       = 1;
        outhdr.descrip = 'Thresholded Mask Image'; 
        putmsg = 'Save mask image as'; 
        deffn = sprintf('%s/Mask_%s.nii', p, n);  
    end
    fn = uiputvol(deffn, putmsg);
    if isempty(fn), disp('User cancelled.'); return; end
    outhdr.fname = fn; 
    spm_write_vol(outhdr, outimg);
    fprintf('\nImage saved to %s\n', fn);         
function cb_saveclust(varargin)
    global st
    str = get(findobj(st.fig, 'tag', 'clustersize'), 'string'); 
    if strcmp(str, 'n/a'), return; end
    [xyz, voxidx] = bspm_XYZreg('NearestXYZ', bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM), st.ol.XYZmm0);
    lab = get(varargin{1}, 'label');
    T = getthresh; 
    di = strcmpi({'+' '-' '+/-'}, T.direct);
    clidx = st.ol.C0IDX(di,:);
    clidx = clidx==(clidx(voxidx)); 
    opt = [1 -1 1]; 
    outimg = st.ol.Y*opt(di);
    outhdr = st.ol.hdr; 
    outimg(clidx==0) = NaN;
    putmsg = 'Save cluster'; 
    outhdr.descrip = 'Intensity Thresholded Cluster Image'; 
    [p,n] = fileparts(outhdr.fname); 
    deffn = sprintf('%s/Cluster_%s_x=%d_y=%d_z=%d_%svoxels.nii', p, n, xyz, str);  
    if regexp(lab, 'binary mask')
        outimg(isnan(outimg))   = 0; 
        outimg(outimg~=0)       = 1;
        outhdr.descrip = 'Binary Mask Cluster Image'; 
        putmsg = 'Save mask image as'; 
        deffn = sprintf('%s/ClusterMask_%s_x=%d_y=%d_z=%d_%svoxels.nii', p, n, xyz, str);   
    end
    fn = uiputvol(deffn, putmsg);
    if isempty(fn), disp('User cancelled.'); return; end
    outhdr.fname = fn; 
    spm_write_vol(outhdr, outimg);
    fprintf('\nCluster image saved to %s\n', fn);     
function cb_hideclust(varargin)
    global st
    str = get(findobj(st.fig, 'tag', 'clustersize'), 'string'); 
    if strcmp(str, 'n/a'), return; end
    [xyz, voxidx] = bspm_XYZreg('NearestXYZ', bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM), st.ol.XYZmm0);
    T = getthresh; 
    di = strcmpi({'+' '-' '+/-'}, T.direct);
    clidx = st.ol.C0IDX(di,:);
    clidx = clidx==(clidx(voxidx));
    st.ol.Y(clidx==1) = 0; 
    cb_updateoverlay
function cb_saveroi(varargin)
    global st
    [roi, button] = settingsdlg(...  
    'title'                     ,   'ROI Parameters', ...
    {'Intersect ROI with Overlay?'; 'intersectflag'}    ,  true, ...
    {'Shape'; 'shape'}          ,   {'Sphere' 'Box'}, ...
    {'Size (mm)'; 'size'}       ,   12);
    if strcmpi(button, 'cancel'), return; end
    [mm, voxidx] = bspm_XYZreg('NearestXYZ', bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM), st.ol.XYZmm0);
    refhdr = st.ol.hdr; 
    roihdr = refhdr;
    roihdr.pinfo = [1;0;0];
    roipath = pwd;
    [R,C,P]  = ndgrid(1:refhdr.dim(1),1:refhdr.dim(2),1:refhdr.dim(3));
    RCP      = [R(:)';C(:)';P(:)'];
    clear R C P
    RCP(4,:)    = 1;
    XYZmm       = refhdr.mat(1:3,:)*RCP;   
    Q           = ones(1,size(XYZmm,2));
    cROI        = zeros(roihdr.dim);
    switch roi.shape
        case 'Sphere'
            j = find(sum((XYZmm - mm*Q).^2) <= roi.size^2);
        case 'Box'
            j      = find(all(abs(XYZmm - mm*Q) <= [roi.size roi.size roi.size]'*Q/2));
    end
    cROI(j) = 1;
    if roi.intersectflag
        T   = getthresh; 
        di  = strcmpi({'+' '-' '+/-'}, T.direct);
        clidx = st.ol.C0IDX(di,:);
        clidx = clidx==(clidx(voxidx)); 
        opt = [1 -1 1]; 
        img = st.ol.Y*opt(di);
        img(clidx==0) = 0;
        cROI = double(cROI & img); 
    end
    cHDR            = roihdr;
    cHDR.descrip    = sprintf('ROI - x=%d, y=%d, z=%d - %s %d', mm, roi.shape, roi.size); 
    [p,n]   = fileparts(cHDR.fname); 
    deffn   = sprintf('%s/ROI_x=%d_y=%d_z=%d_%dvoxels_%s%d.nii', p, mm, sum(cROI(:)), roi.shape, roi.size);  
    putmsg  = 'Save ROI as'; 
    fn      = uiputvol(deffn, putmsg);
    if isempty(fn), disp('User cancelled.'); return; end
    cHDR.fname = fn; 
    spm_write_vol(cHDR,cROI);
    fprintf('\nROI image saved to %s\n', fn);     
function cb_savergb(varargin)
    %% Handles for axes
    % 1 - transverse
    % 2 - coronal
    % 3 - sagittal 
    % st.vols{1}.ax{1}.ax   - axes
    % st.vols{1}.ax{1}.d    - image
    % st.vols{1}.ax{1}.lx   - crosshair (x)
    % st.vols{1}.ax{1}.ly   - crosshair (y)
    global st
    setbackgcolor;
    im = screencapture(st.fig);
    setbackgcolor(st.color.bg)
    [imname, pname] = uiputfile({'*.png; *.jpg; *.pdf', 'Image'; '*.*', 'All Files (*.*)'}, 'Specify output directory and name', construct_filename);
    if isempty(imname), disp('User cancelled.'); return; end
    imwrite(im, fullfile(pname, imname)); 
    fprintf('\nImage saved to %s\n', fullfile(pname, imname));   
function cb_changeguisize(varargin)
    global st
    F = 0.9; 
    if strcmp(get(varargin{1}, 'Label'), 'Increase'), F = 1.1; end
    guipos = get(st.fig, 'pos');
    guipos(3:4) = guipos(3:4)*F; 
    set(st.fig, 'pos', guipos);
    pause(.50);
    drawnow;
function cb_changefontsize(varargin)
    global st
    minsize = 5; 
    F = -1; 
    if strcmp(get(varargin{1}, 'Label'), 'Increase'), F = 1; end
    setfontunits('points'); 
    h   = findall(st.fig, '-property', 'FontSize');
    fs  = cell2mat(get(h, 'FontSize')) + F;
    h(fs<minsize) = []; 
    fs(fs<minsize)  = [];
    arrayfun(@set, h, repmat({'FontSize'}, length(h), 1), num2cell(fs))
    pause(.50);
    drawnow;
    setfontunits('norm'); 
function cb_changeskin(varargin)
    if strcmpi(get(varargin{1},'Checked'), 'on'), return; end
    global st
    skin = get(varargin{1}, 'Label');
    h       = gethandles; 
    switch lower(skin)
        case {'dark'}
            st.color = default_colors(1);
            set(findobj(st.fig, 'Label', 'Dark'), 'Checked', 'on'); 
            set(findobj(st.fig, 'Label', 'Light'), 'Checked', 'off'); 
        case {'light'}
            st.color = default_colors(0);
            set(findobj(st.fig, 'Label', 'Dark'), 'Checked', 'off'); 
            set(findobj(st.fig, 'Label', 'Light'), 'Checked', 'on'); 
    end
    set(st.fig, 'color', st.color.bg); 
    set(findall(st.fig, '-property', 'ycolor'), 'ycolor', st.color.bg);
    set(findall(st.fig, '-property', 'xcolor'), 'xcolor', st.color.bg);
    al = findall(h.lowerpanel, 'type', 'axes'); 
    ul = findall(h.upperpanel, 'type', 'axes'); 
    set([al; ul], 'color', st.color.bg); 
    al = findall(h.lowerpanel, 'type', 'text'); 
    ul = findall(h.upperpanel, 'type', 'text'); 
    set([al; ul], 'color', st.color.fg); 
    set(findall(st.fig, 'type', 'uipanel'), 'backg', st.color.bg, 'foreg', st.color.fg);
    set(findall(st.fig, 'type', 'uicontrol', 'style', 'text'), 'backg', st.color.bg, 'foreg', st.color.fg);
    set(findall(st.fig, 'style', 'radio'), 'backg', st.color.bg, 'foreg', st.color.fg);
    set(h.colorbar, 'ycolor', st.color.fg); 
    set(varargin{1}, 'Checked', 'on'); 
    drawnow;
function cb_correct(varargin)
    global st
    str = get(varargin{1}, 'string');
    methodstr = str{get(varargin{1}, 'value')};
    T0 = getthresh;
    T = T0; 
    di = strcmpi({'+' '-' '+/-'}, T.direct); 
    switch methodstr
        case {'None'}
            return
        case {'Voxel FWE'}
            T.thresh    = voxel_correct(st.ol.fname, st.preferences.alphacorrect);
            T.pval      = bob_t2p(T.thresh, T.df);
        case {'Cluster FWE'}
            T.extent = cluster_correct(st.ol.fname, T0.pval, st.preferences.alphacorrect);
    end
    [st.ol.C0, st.ol.C0IDX] = getclustidx(st.ol.Y, T.thresh, T.extent);
    C = st.ol.C0(di,:); 
    if sum(C(C>=T.extent))==0
        T0.thresh = st.ol.U; 
        setthreshinfo(T0);
        headsup('Nothing survived. Showing original threshold.');
        set(varargin{1}, 'value', 1); 
        return
    end
    setthresh(C, find(di)); 
    setthreshinfo(T);  
function cb_preferences(varargin)
    global st
    default_preferences; 
function cb_reversemap(varargin)
    state = get(varargin{1},'Checked');
    if strcmpi(state,'on');
        set(varargin{1},'Checked','off');
    else
        set(varargin{1},'Checked','on');
    end
    global st
    for i = 1:size(st.cmap, 1)
       st.cmap{i,1} = st.cmap{i,1}(end:-1:1,:); 
    end
    setcolormap;  
function cb_render(varargin)
    global st
    T = getthresh; 
    direct = char(T.direct); 
    obj = []; 
    obj.cmapflag = st.preferences.colorbar;   
    obj.round = st.preferences.round;                 
    obj.shadingrange = [st.preferences.shadingmin st.preferences.shadingmax];
    obj.Nsurfs = st.preferences.surfshow ;               
    switch st.preferences.nverts
        case 642
            obj.fsaverage = 'fsaverage3.mat';
        case 2562
            obj.fsaverage = 'fsaverage4.mat';
        case 10242
            obj.fsaverage = 'fsaverage5.mat';
        case 40962
            obj.fsaverage = 'fsaverage6.mat';
        case 163842
            obj.fsaverage = 'fsaverage.mat';
        otherwise
    end
    obj.background      = [0 0 0];
    obj.mappingfile     = [];         
    obj.fsaverage       = fullfile(st.supportpath, obj.fsaverage); 
    obj.medialflag      = 1; 
    obj.direction       = direct; 
    obj.surface         = st.preferences.surface; 
    obj.shading         = st.preferences.shading;
    obj.colorlims       = [st.vols{1}.blobs{1}.min st.vols{1}.blobs{1}.max];
    obj.input.m         = st.ol.Y; 
    di = {'+' '-' '+/-'}; 
    obj.input.m(st.ol.C0IDX(strcmpi(di, direct),:)==0) = 0; 
    obj.input.he        = st.ol.hdr; 
    obj.figno = 0;
    obj.newfig = 1;
    obj.overlaythresh = T.thresh;
    if strcmpi(direct, '+/-')
        obj.overlaythresh = [T.thresh*-1 T.thresh];
    elseif strcmpi(direct, '-')
        obj.input.m = obj.input.m*-1;
    end
    val = get(findobj(st.fig, 'Tag', 'colormaplist'), 'Value'); 
    obj.colormap = st.cmap{val, 1}; 
    obj.reverse = 0; 
    ss = get(0, 'ScreenSize');
    ts = floor(ss/2);     
    switch obj.Nsurfs
    case 4
       ts(4) = ts(4)*.90;
    case 2
       ts(4) = ts(4)*.60;
    case 'L Lateral'
       obj.Nsurfs = -1;
    case 1.9
       ts(4) = ts(4)*.60;
    case 2.1
       ts(4) = ts(4)*.60;
    otherwise
    end
    obj.position = ts; 
    [h1, hh1] = surfPlot4(obj);
    drawnow;
function cb_report(varargin)
    global st
    T = getthresh;
    di = strcmpi({'+' '-' '+/-'}, T.direct);
    opt = {'pos' 'neg' 'pos'}; 
    peaknii  = struct( ...
        'thresh', T.thresh, ...
        'cluster'  ,   T.extent, ...
        'separation',   st.preferences.separation, ...
        'sign',  opt{di}, ...
        'nearest',   1, ...
        'type',     'T', ...
        'out',   '', ...
        'voxlimit',   [], ...
        'SPM',   [], ...
        'conn',   [], ...
        'round',   [], ...
        'mask', [], ...
        'df1', [], ...
        'df2', []); 
    voxels = peak_nii(st.ol.fname, peaknii);
    
    % get table position
    ss = get(0, 'ScreenSize');
    ts = floor(ss/3);
    fs = get(st.fig, 'Position');
    if ss(3)-sum(fs([1 3])) > ts(3)
        ts(1) = sum(fs([1 3]));
    else
        ts(1) = fs(1)-ts(3);
    end
    ts([2 4]) = fs([2 4]);

    % create table
    tfig  = figure('pos', ts, 'DockControls','off', 'MenuBar', 'none', 'Name', 'Report', 'Color', [1 1 1], 'NumberTitle', 'off', 'Visible', 'off'); 
    tfigmenu  = uimenu(tfig,'Label','Options');
    uimenu(tfigmenu,'Label','Save Report to CSV', 'CallBack', @cb_savetable);
    header  = {'Region Name' 'Extent' 'Stat' 'X' 'Y' 'Z'}; 
    colwidth = repmat({'auto'}, 1, length(header)); 
    colwidth{1} = floor(ss(3)/10);
    th = uitable('Parent', tfig, ...
        'Data', voxels, ...
        'Units', 'norm', ...
        'ColumnName', header, ...
        'Pos', [0 0 1 1], ...
        'RearrangeableColumns', 'on', ...
        'ColumnWidth', colwidth, ...
        'FontName', 'Fixed-Width', ...
        'FontUnits', 'Points', ...
        'FontSize', st.fonts.sz4, ...
        'CellSelectionCallback',@cb_tablexyz);
    set(th, 'units', 'pix'); 
    tpos    = get(th, 'extent');
    fpos    = get(tfig, 'pos'); 
    set(tfig, 'pos', [fpos(1:2) tpos(3:4)]);
    set(th, 'units', 'norm');
    set(th, 'pos', [0 0 1 1]); 
    set(tfig, 'vis', 'on');
    drawnow;
function cb_savetable(varargin)
    global st
    T = getthresh;
    di = strcmpi({'+' '-' '+/-'}, T.direct);
    opt = {'pos' 'neg' 'pos'}; 
    peaknii  = struct( ...
        'thresh', T.thresh, ...
        'cluster'  ,   T.extent, ...
        'separation',   st.preferences.separation, ...
        'sign',  opt{di}, ...
        'nearest',   1, ...
        'type',     'T', ...
        'out',   '', ...
        'voxlimit',   [], ...
        'SPM',   [], ...
        'conn',   [], ...
        'round',   [], ...
        'mask', [], ...
        'df1', [], ...
        'df2', []); 
    voxels = peak_nii(st.ol.fname, peaknii);
    headers1 = {'' '' '' 'MNI Coordinates' '' ''};
    headers2 = {'Region Name' 'Extent' 't-value' 'x' 'y' 'z'};
    allcell = [headers1; headers2; voxels];
    [p, imname] = fileparts(st.ol.fname);
    outname = ['save_table_' imname '_I' num2str(peaknii.thresh) '_C' num2str(peaknii.cluster) '_S' num2str(peaknii.separation) '.csv'];
    [fname, pname] = uiputfile({'*.csv', 'Spreadsheet Table'; '*.*', 'All Files (*.*)'}, 'Save Table As', outname);
    writereport(allcell, fullfile(pname, fname)); 
function cb_web(varargin)
    stat = web(varargin{3}, '-browser');
    if stat, headsup('Could not open a browser window.'); end
function cb_checkversion(varargin)
    global version
    url     = 'https://github.com/spunt/bspmview/blob/master/README.md';
    h       = headsup('Checking GitHub repository. Please be patient.', 'Checking Version', 0);
    try
        str = webread(url);
    catch
        set(h(2), 'String', 'Could not read web data. Are you connected to the internet?');
        figure(h(1)); 
        return
    end
    [idx1, idx2] = regexp(str, 'Version:  ');
    gitversion = str(idx2+1:idx2+8);
    if strcmp(version, gitversion)
        delete(h(1)); 
        headsup('You have the latest version.', 'Checking Version', 1);
        return; 
    else
        delete(h(1)); 
        answer = yesorno('An update is available. Would you like to download the latest version?', 'Update Available');
        if strcmpi(answer, 'Yes')
            guidir      = fileparts(mfilename('fullpath')); 
            newguidir   = fullfile(fileparts(guidir), 'bspmview-master');
            url         = 'https://github.com/spunt/bspmview/archive/master.zip';
            h = headsup('Downloading...', 'Please Wait', 0);
            unzip(url, fileparts(guidir));
            delete(h(1));
            h = headsup(sprintf('Latest version saved to: %s', newguidir), 'Update', 1);
        else
            return; 
        end
    end     
function cb_neurosynth(varargin)
    baseurl = 'http://neurosynth.org/locations/?x=%d&y=%d&z=%d&r=6';
    stat = web(sprintf(baseurl, getroundvoxel), '-browser');
    if stat, headsup('Could not open a browser window..'); end
function cb_closegui(varargin)
   if length(varargin)==3, h = varargin{3};
   else h = varargin{1}; end
   rmpath(fullfile(fileparts(mfilename('fullpath')), 'supportfiles')); 
   delete(h); % Bye-bye figure
   
% | SETTERS
% =========================================================================
function setcolormap(varargin)
    global st
    val = get(findobj(st.fig, 'Tag', 'colormaplist'), 'Value'); 
    newmap = st.cmap{val, 1}; 
    cbh = st.vols{1}.blobs{1}.cbar; 
    cmap = [gray(64); newmap];
    set(findobj(cbh, 'type', 'image'), 'CData', (65:128)', 'CdataMapping', 'direct');
    set(st.fig,'Colormap', cmap);
    bspm_orthviews('SetBlobsMax', 1, 1, max(st.ol.Z))
    set(findobj(st.fig, 'tag', 'maxval'), 'str',  sprintf('%2.3f',max(st.ol.Z)));
    drawnow;
function setfontunits(unitstr)
    if nargin==0, unitstr = 'norm'; end
    global st
    arrayset(findall(st.fig, '-property', 'fontunits'), 'fontunits', unitstr);
    drawnow; 
function setunits
    global st
    arrayset(findall(st.fig, '-property', 'units'), 'units', 'norm');
    set(st.fig, 'units', 'pixels'); 
    drawnow; 
function setposition_axes
    global st
    CBPIXSIZE = 100; 
    %% Handles for axes
    % 1 - transverse
    % 2 - coronal
    % 3 - sagittal 
    % st.vols{1}.ax{1}.ax   - axes
    % st.vols{1}.ax{1}.d    - image
    % st.vols{1}.ax{1}.lx   - crosshair (x)
    % st.vols{1}.ax{1}.ly   - crosshair (y)
    h = gethandles_axes;
    axpos = cell2mat(get(h.ax, 'pos'));
    axpos(1:2, 1)   = 0; 
    axpos(1, 2)     = 0;
    axpos(3, 1)     = sum(axpos(2,[1 3]))+.005; 
    axpos(2:3, 2)   = sum(axpos(1,[2 4]))+.005;
    pz  = axpos(1,:);
    py  = axpos(2,:);
    px  = axpos(3,:);
    zrat = pz(3)/pz(4);
    yrat = py(3)/py(4);
    xrat = px(3)/px(4);
    VL = sum(py([2 4])); 
    while VL < 1
        px(4) = px(4) + .001; 
        px(3) = px(4)*xrat; 
        py(4) = px(4); 
        py(3) = py(4)*yrat; 
        pz(3) = py(3); 
        pz(4) = pz(3)/zrat; 
        px(1) = sum(py([1 3]))+.005;
        py(2) = sum(pz([2 4]))+.005;
        px(2) = py(2); 
        VL = sum(py([2 4]));
    end
    axpos = [pz; py; px]; 
    for a = 1:3, set(h.ax(a), 'position', axpos(a,:)); end
    set(h.ax, 'units', 'pixels'); 
    axpos = cell2mat(get(h.ax, 'pos'));
    HL = round(sum(axpos(3, [1 3])) + CBPIXSIZE); 
    figsize = get(st.fig, 'pos'); 
    figsize(3) = HL; 
    set(st.fig, 'pos', figsize);
    for a = 1:3, set(h.ax(a), 'position', axpos(a,:)); end
    set(h.ax, 'units', 'norm');
    % deal with lower panel
    p = findobj(st.fig, 'tag', 'lowerpanel');
    unit0 = get(p, 'units');
    apos = get(h.ax(1), 'pos'); 
    ppos = [sum(apos([1 3]))+.01 apos(2) 1-.02-sum(apos([1 3])) apos(4)]; 
    set(p, 'units', 'norm', 'pos', ppos); 
    set(p, 'units', unit0); 
    bspm_orthviews('Redraw');
function setthreshinfo(T)
    global st
    if nargin==0
        T = struct( ...
            'extent',   st.ol.K, ...
            'thresh',   st.ol.U, ...
            'pval',     st.ol.P, ...
            'df',       st.ol.DF, ...
            'direct',   st.direct);
    end
    st.direct = char(T.direct); 
    Tval = [T.extent T.thresh T.pval T.df]; 
    Tstr = {'Extent' 'Thresh' 'P-Value' 'DF'};
    Tstrform = {'%d' '%2.2f' '%2.3f' '%d'}; 
    for i = 1:length(Tstr)
        set(findobj(st.fig, 'Tag', Tstr{i}), 'String', sprintf(Tstrform{i}, Tval(i)));
    end
function setthresh(C, di)
    global st
    if nargin==1, di = 3; end
    idx = find(C > 0); 
    st.ol.Z     = st.ol.Y(idx);
    if di~=3, st.ol.Z = abs(st.ol.Y(idx)); end
    st.ol.XYZ   = st.ol.XYZ0(:,idx);
    st.ol.XYZmm = st.ol.XYZmm0(:,idx);
    st.ol.C     = C(idx); 
    st.ol.atlas = st.ol.atlas0(idx); 
    set(findobj(st.fig, 'Tag', 'maxval'), 'str', sprintf('%2.3f',max(st.ol.Z)));
    bspm_orthviews('RemoveBlobs', st.ho);
    bspm_orthviews('AddBlobs', st.ho, st.ol.XYZ, st.ol.Z, st.ol.M);
    bspm_orthviews('Register', st.registry.hReg);
    setcolormap; 
    bspm_orthviews('Reposition');
function [voxval, clsize] = setvoxelinfo
    global st
    [nxyz,voxidx, d]    = getnearestvoxel; 
    [xyz, xyzidx, dist] = getroundvoxel;
    regionidx = st.ol.atlas0(xyzidx);
    if regionidx
        regionname = st.ol.atlaslabels.label{st.ol.atlaslabels.id==regionidx};
    else
        regionname = 'n/a'; 
    end
    if d > min(st.ol.VOX)
        voxval = 'n/a'; 
        clsize = 'n/a';
    else
        voxval = sprintf('%2.3f', st.ol.Z(voxidx));
        clsize = sprintf('%d', st.ol.C(voxidx));
    end
    set(findobj(st.fig, 'tag', 'Location'), 'string', regionname); 
    set(findobj(st.fig, 'tag', 'xyz'), 'string', sprintf('%d, %d, %d', xyz)); 
    set(findobj(st.fig, 'tag', 'voxval'), 'string', voxval); 
    set(findobj(st.fig, 'tag', 'clustersize'), 'string', clsize);
    axidx = [3 2 1];
    for a = 1:length(axidx)
        set(st.vols{1}.ax{axidx(a)}.xyz, 'string', num2str(xyz(a)));
    end
    drawnow; 
function setbackgcolor(newcolor)
    global st
    if nargin==0, newcolor = st.color.bg; end
    prop = {'backg' 'ycolor' 'xcolor' 'zcolor'}; 
    for i = 1:length(prop)
        set(findobj(st.fig, prop{i}, st.color.bg), prop{i}, newcolor); 
    end
    h = gethandles_axes;
    set(h.ax, 'ycolor', newcolor, 'xcolor', newcolor); 
    drawnow;
function setxhaircolor(varargin)
    global st
    h = gethandles_axes;
    set(h.lx, 'color', st.color.xhair); 
    set(h.ly, 'color', st.color.xhair);
    drawnow;

% | GETTERS
% =========================================================================
function h = gethandles(varargin)
    global st
    h.axial = st.vols{1}.ax{1}.ax;
    h.coronal = st.vols{1}.ax{2}.ax;
    h.sagittal = st.vols{1}.ax{3}.ax;
    h.colorbar = st.vols{1}.blobs{1}.cbar;
    h.upperpanel = findobj(st.fig, 'tag', 'upperpanel'); 
    h.lowerpanel = findobj(st.fig, 'tag', 'lowerpanel'); 
function [clustsize, clustidx] = getclustidx(rawol, u, k)

    % raw data to XYZ
    DIM         = size(rawol); 
    [X,Y,Z]     = ndgrid(1:DIM(1),1:DIM(2),1:DIM(3));
    XYZ         = [X(:)';Y(:)';Z(:)'];
    pos  = zeros(1, size(XYZ, 2)); 
    neg  = pos; 
    clustidx = zeros(3, size(XYZ, 2));
    
    % positive
    supra = (rawol(:)>=u)';    
    if sum(supra)
        tmp      = spm_clusters(XYZ(:, supra));
        clbin      = repmat(1:max(tmp), length(tmp), 1)==repmat(tmp', 1, max(tmp));
        pos(supra) = sum(repmat(sum(clbin), size(tmp, 2), 1) .* clbin, 2)';
        clustidx(1,supra) = tmp;
    end
    pos(pos < k)    = 0; 
    
    % negative
    rawol = rawol*-1; 
    supra = (rawol(:)>=u)';    
    if sum(supra)
        tmp      = spm_clusters(XYZ(:, supra));
        clbin      = repmat(1:max(tmp), length(tmp), 1)==repmat(tmp', 1, max(tmp));
        neg(supra) = sum(repmat(sum(clbin), size(tmp, 2), 1) .* clbin, 2)';
        clustidx(2,supra) = tmp;
    end
    neg(neg < k) = 0;
     
    % both
    clustsize = [pos; neg]; 
    clustsize(3,:) = sum(clustsize);
    clustidx(3,:) = sum(clustidx); 
function [h, axpos] = gethandles_axes(varargin)
    global st
    axpos = zeros(3,4);
    if isfield(st.vols{1}, 'blobs');
        h.cb = st.vols{1}.blobs{1}.cbar; 
    end
    for a = 1:3
        tmp = st.vols{1}.ax{a};
        h.ax(a) = tmp.ax; 
        h.d(a)  = tmp.d;
        h.lx(a) = tmp.lx; 
        h.ly(a) = tmp.ly;
        axpos(a,:) = get(h.ax(a), 'position');
    end
function T = getthresh
    global st
    T.extent = str2num(get(findobj(st.fig, 'Tag', 'Extent'), 'String')); 
    T.thresh = str2num(get(findobj(st.fig, 'Tag', 'Thresh'), 'String'));
    T.pval = str2num(get(findobj(st.fig, 'Tag', 'P-Value'), 'String'));
    T.df = str2num(get(findobj(st.fig, 'Tag', 'DF'), 'String'));
    tmph = findobj(st.fig, 'Tag', 'direct'); 
    opt = get(tmph, 'String');
    T.direct = opt(find(cell2mat(get(tmph, 'Value'))));
    if strcmp(T.direct, 'pos/neg'), T.direct = '+/-'; end   
function [xyz, xyzidx, dist] = getroundvoxel
    global st
    [xyz, dist] = bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM); 
    xyzidx      = bspm_XYZreg('FindXYZ', xyz, st.ol.XYZmm0); 
function [xyz, voxidx, dist] = getnearestvoxel 
    global st
    [xyz, voxidx, dist] = bspm_XYZreg('NearestXYZ', bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM), st.ol.XYZmm);
    
% | BUIPANEL
% =========================================================================
function h      = buipanel(parent, uilabels, uistyles, relwidth, varargin)
% BUIPANEL Create a panel and populate it with uicontrols
%
%  USAGE: h = buipanel(parent, uilabels, uistyles, uiwidths, varargin)
% __________________________________________________________________________
%  INPUTS 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-10-08
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
global st
easyparse(varargin, ... 
            { ...
            'panelposition', ...
            'paneltitleposition', ...
            'paneltitle', ...
            'panelborder', ... 
            'panelbackcolor',  ...
            'panelforecolor', ...
            'panelfontsize',  ...
            'panelfontname' ...
            'panelfontweight', ...
            'editbackcolor',  ...
            'editforecolor', ...
            'editfontsize',  ...
            'editfontname', ...
            'labelbackcolor',  ...
            'labelforecolor', ...
            'labelfontsize',  ...
            'labelfontname', ...
            'labelfontweight', ...
            'relheight', ...
            'marginsep', ...
            'uicontrolsep', ...
            'tag'}); 
defaults = easydefaults(...
            'paneltitleposition', 'centertop', ...
            'panelborder',      'none', ... 
            'panelbackcolor',   st.color.bg, ...
            'editbackcolor',    st.color.fg, ...
            'labelbackcolor',   st.color.bg, ...
            'panelforecolor',   st.color.fg, ...
            'editforecolor',    [0 0 0], ...
            'labelforecolor',   st.color.fg, ...
            'panelfontname',    st.fonts.name, ...
            'editfontname',     'fixed-width', ...
            'labelfontname',    st.fonts.name, ...
            'panelfontsize',    st.fonts.sz2, ...
            'editfontsize',     st.fonts.sz3, ...
            'labelfontsize',    st.fonts.sz3, ...
            'panelfontweight',  'bold', ...
            'labelfontweight',  'bold', ...
            'relheight',        [6 7], ...
            'marginsep',        .025, ...
            'uicontrolsep',     .025);
if nargin==0, mfile_showhelp; disp(defaults); return; end

% | UNITS
unit0 = get(parent, 'units'); 
        
% | PANEL
set(parent, 'units', 'pixels')
pp          = get(parent, 'pos'); 
pp          = [pp(3:4) pp(3:4)]; 
P           = uipanel(parent, 'units', 'pix', 'pos', panelposition.*pp, 'title', paneltitle, ...
            'backg', panelbackcolor, 'foreg', panelforecolor, 'fontsize', panelfontsize, ...
            'fontname', panelfontname, 'bordertype', panelborder, 'fontweight', panelfontweight, 'titleposition', paneltitleposition);
labelprop   = {'parent', P, 'style', 'text', 'units', 'norm', 'fontsize', labelfontsize, 'fontname', labelfontname, 'foreg', labelforecolor, 'backg', labelbackcolor, 'fontweight', labelfontweight, 'tag', 'uilabel'}; 
editprop    = {'parent', P, 'units', 'norm', 'fontsize', editfontsize, 'fontname', editfontname, 'foreg', editforecolor, 'backg', editbackcolor}; 
propadd     = {'tag'};

% | UICONTROLS

pos         = getpositions(relwidth, relheight, marginsep, uicontrolsep);
editpos     = pos(pos(:,1)==1,3:6); 
labelpos    = pos(pos(:,1)==2, 3:6); 
hc          = zeros(length(uilabels), 1);
he          = zeros(length(uilabels), 1); 
for i = 1:length(uilabels)
    ctag = ~cellfun('isempty', regexpi({'editbox', 'slider', 'listbox', 'popup'}, uistyles{i}));
    ttag = ~cellfun('isempty', regexpi({'text'}, uistyles{i}));
    if sum(ctag)==1
        hc(i) = uibutton(labelprop{:}, 'pos', labelpos(i,:), 'str', uilabels{i}); 
        he(i) = uicontrol(editprop{:}, 'style', uistyles{i}, 'pos', editpos(i,:));
    elseif ttag
        editpos(i,4) = 1 - marginsep*2; 
        he(i) = uibutton(labelprop{:}, 'style', uistyles{i}, 'pos', editpos(i,:), 'str', uilabels{i}); 
    else
        editpos(i,4) = 1 - marginsep*2; 
        he(i) = uicontrol(labelprop{:}, 'style', uistyles{i}, 'pos', editpos(i,:), 'str', uilabels{i});  
    end
    for ii = 1:length(propadd)
           if ~isempty(propadd{ii})
                tmp = eval(sprintf('%s', propadd{ii})); 
                set(he(i), propadd{ii}, tmp{i}); 
           end
    end
end
% | HANDLES
h.panel = P;
h.label = hc; 
h.edit  = he;  

set(parent, 'units', unit0);
function pos    = getpositions(relwidth, relheight, marginsep, uicontrolsep)
    if nargin<2, relheight = [6 7]; end
    if nargin<3, marginsep = .025; end
    if nargin<4, uicontrolsep = .01; end
    ncol = length(relwidth);
    nrow = length(relheight); 

    % width
    rowwidth    = 1-(marginsep*2)-(uicontrolsep*(ncol-1));  
    uiwidths    = (relwidth/sum(relwidth))*rowwidth;
    allsep      = [marginsep repmat(uicontrolsep, 1, ncol-1)];
    uilefts     = ([0 cumsum(uiwidths(1:end-1))]) + cumsum(allsep); 

    % height
    colheight   = 1-(marginsep*2)-(uicontrolsep*(nrow-1));
    uiheights   = (relheight/sum(relheight))*colheight;
    allsep      = [marginsep repmat(uicontrolsep, 1, nrow-1)];
    uibottoms   = ([0 cumsum(uiheights(1:end-1))]) + cumsum(allsep);

    % combine
    pos = zeros(ncol, 4, nrow);
    pos(:,1,:)  = repmat(uilefts', 1, nrow); 
    pos(:,2,:)  = repmat(uibottoms, ncol, 1);
    pos(:,3,:)  = repmat(uiwidths', 1, nrow);
    pos(:,4,:)  = repmat(uiheights, ncol, 1);

    % test
    pos = zeros(ncol*nrow, 6);
    pos(:,1) = reshape(repmat(1:nrow, ncol, 1), size(pos,1), 1);
    pos(:,2) = reshape(repmat(1:ncol, 1, nrow), size(pos,1), 1);
    pos(:,3) = uilefts(pos(:,2)); 
    pos(:,4) = uibottoms(pos(:,1)); 
    pos(:,5) = uiwidths(pos(:,2)); 
    pos(:,6) = uiheights(pos(:,1)); 

% | IMAGE PROCESSING UTILITIES
% =========================================================================
function OL = load_overlay(fname, pval, k)
    global st
    if nargin<3, k = 5; end
    if nargin<2, pval = .001; end
    badfn = 1; 
    while badfn
        oh = spm_vol(fname); 
        od = spm_read_vols(oh);
        od(isnan(od)) = 0;
        if sum(od(:))==0
            headsup('Your image file is empty. Please try a different file.')
            fname = uigetvol('Select an Image File for Overlay', 0);
            if isempty(fname), disp('Must select an overlay!'); return; end
        else
            badfn = 0; 
        end
    end

    %% CHECK IMAGE
    allh = findobj(st.fig, 'Tag', 'direct'); 
    if ~isempty(allh), cb_directmenu(st.direct); end
    posneg = [sum(od(:)>0) sum(od(:)<0)]==0; 
    if any(posneg)
        opt = {'+' '-'}; 
        st.direct = lower(opt{posneg==0});
        if ~isempty(allh)
            allhstr = get(allh, 'String');
            set(allh(strcmp(allhstr, '+/-')), 'Value', 0, 'Enable', 'inactive');
            set(allh(strcmp(allhstr, opt{posneg})), 'Value', 0, 'Enable', 'inactive');
            set(allh(strcmp(allhstr, opt{~posneg})), 'Value', 1, 'Enable', 'inactive'); 
        end
    end

    %% DEGREES OF FREEDOM
    tmp = oh.descrip;
    idx{1} = regexp(tmp,'[','ONCE');
    idx{2} = regexp(tmp,']','ONCE');
    if any(cellfun('isempty', idx))
        headsup('Degrees of freedom not found in image header. Showing unthresholded image.')
        u = 0.01;
        k = 1;
        df = Inf;
        pval = Inf; 
    else
        df = str2num(tmp(idx{1}+1:idx{2}-1));
        u = spm_invTcdf(1-pval, df);  
    end
    [C, I] = getclustidx(od, u, k);
    if ~any(C(:))
        headsup('No suprathreshold voxels. Showing unthresholded image.'); 
        u = 0; 
        pval = bob_t2p(u, df);
        k = 1; 
        [C, I] = getclustidx(od, u, k); 
    end
    M           = oh.mat;         %-voxels to mm matrix
    DIM         = oh.dim';
    VOX         = abs(diag(M(:,1:3))); 
    [X,Y,Z]     = ndgrid(1:DIM(1),1:DIM(2),1:DIM(3));
    XYZ        = [X(:)';Y(:)';Z(:)'];
    RCP         = XYZ; 
    RCP(4,:)    = 1;
    XYZmm      = M(1:3,:)*RCP;
    OL          = struct( ...
                'fname',    fname,...
                'descrip',  oh.descrip, ...
                'hdr',      oh, ...
                'DF',       df, ...
                'null',     posneg, ...
                'U',        u, ...
                'P',        pval, ...
                'K',        k, ...
                'Y',        od, ...
                'M',        M,...
                'DIM',      DIM,...
                'VOX',      VOX, ...
                'C0',        C, ...
                'C0IDX',       I, ...
                'XYZmm0',    XYZmm,...
                'XYZ0',      XYZ);    
            
    %% LABEL MAP
    atlas_vol = fullfile(st.supportpath, sprintf('%s_Atlas_Map.nii', st.preferences.atlasname)); 
    atlas_labels = fullfile(st.supportpath, sprintf('%s_Atlas_Labels.mat', st.preferences.atlasname)); 
    atlasvol = reslice_image(atlas_vol, fname);
    atlasvol = single(round(atlasvol(:)))'; 
    load(atlas_labels);
    OL.atlaslabels = atlas; 
    OL.atlas0 = atlasvol;    
    set(st.fig, 'Name', abridgepath(OL.fname)); 
function u  = voxel_correct(im,alpha)
if nargin < 1, error('USAGE: u = voxel_correct(im,alpha)'); end
if nargin < 2, alpha = .05; end
if iscell(im), im = char(im); end

%% Get Design Variable %%
[impath imname] = fileparts(im);
if exist([impath filesep 'I.mat'],'file') 
    matfile = [impath filesep 'I.mat']; 
    maskfile = [impath filesep 'mask.nii'];
elseif exist([impath filesep 'SPM.mat'],'file') 
    matfile = [impath filesep 'SPM.mat'];
else
    disp('Could not find an SPM.mat or I.mat variable, exiting.'); return
end

%% Defaults %%
STAT = 'T';    % Test statistic
n = 1; % number of conjoint SPMs

%% Determime SPM or GLMFLEX %%
if strfind(matfile,'SPM.mat'), flexflag = 0; else flexflag = 1; end

%% Load and Compute Params %%
if flexflag % GLMFLEX
    load(matfile);
    try
        mask.hdr = spm_vol([I.OutputDir filesep 'mask.nii']);
    catch
        [p mf] = fileparts(im);
        mask.hdr = spm_vol([p filesep 'mask.nii']);
    end
    mask.data = spm_read_vols(mask.hdr);
    img.hdr = spm_vol(im);
    img.data = spm_read_vols(img.hdr);
    tmp = img.hdr.descrip; i1 = find(tmp=='['); i2 = find(tmp==']');
    df = str2num(tmp(i1(1)+1:i2(1)-1));
    df = [1 df];    
    
    FWHM = I.FWHM{1};
    R = spm_resels_vol(mask.hdr,FWHM)';
    S = sum(mask.data(:)==1);
    M = I.v.mat;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHMmm= FWHM.*VOX; % FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM)));% voxels to resels

else % SPM
    
    load(matfile)
    df   = [1 SPM.xX.erdf];
    n    = 1;
    R    = SPM.xVol.R;
    S    = SPM.xVol.S;
    M    = SPM.xVol.M;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHM = SPM.xVol.FWHM;
    FWHMmm= FWHM.*VOX; 				% FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM))); %-voxels to resels
    
end
%% get threshold
u = spm_uc(alpha,df,STAT,R,n,S); 
function k  = cluster_correct(im,u,alpha,range)
% BOB_SPM_CLUSTER_CORRECT Computer extent for cluster-level correction
%
% USAGE: [k info] = bob_spm_cluster_correct(im,u,alpha,range)
%
%
% THIS IS A MODIFICATION OF A FUNCTION BY DRS. THOMAS NICHOLS AND MARKO
% WILKE, CorrClusTh.m. ORIGINAL DOCUMENTATION PASTED BELOW:
%
% Find the corrected cluster size threshold for a given alpha
% function [k,Pc] =CorrClusTh(SPM,u,alpha,guess)
% SPM   - SPM data structure
% u     - Cluster defining threshold
%         If less than zero, u is taken to be uncorrected P-value
% alpha - FWE-corrected level (defaults to 0.05)
% guess - Set to NaN to use a Newton-Rhapson search (default)
%         Or provide a explicit list (e.g. 1:1000) of cluster sizes to
%         search over.
%         If guess is a (non-NaN) scalar nothing happens, except the the
%         corrected P-value of guess is printed. 
%
% Finds the corrected cluster size (spatial extent) threshold for a given
% cluster defining threshold u and FWE-corrected level alpha. 
%
%_________________________________________________________________________
% $Id: CorrClusTh.m,v 1.12 2008/06/10 19:03:13 nichols Exp $ Thomas Nichols, Marko Wilke
if nargin < 1
    disp('USAGE: [k info] = bob_spm_cluster_correct(im,u,alpha,range)'); 
    return; 
end
if nargin < 2, u = .001; end
if nargin < 3, alpha = .05; end
if nargin < 4, range = 5:200; end
if iscell(im), im = char(im); end

%% Get Design Variable %%
[impath, imname] = fileparts(im);
if exist([impath filesep 'I.mat'],'file') 
    matfile = [impath filesep 'I.mat']; 
    maskfile = [impath filesep 'mask.nii'];
elseif exist([impath filesep 'SPM.mat'],'file') 
    matfile = [impath filesep 'SPM.mat'];
else
    disp('Could not find an SPM.mat or I.mat variable, exiting.'); extent = []; info = []; return
end

%% Defaults %%
epsP = 1e-6;   % Corrected P-value convergence criterion (fraction of alpha)
du   = 1e-6;   % Step-size for Newton-Rhapson
maxi = 100;    % Maximum interations for refined search
STAT = 'T';    % Test statistic

%% Determime SPM or GLMFLEX %%
if strfind(matfile,'SPM.mat'), flexflag = 0; else flexflag = 1; end

%% Load and Compute Params %%
if flexflag % GLMFLEX
    II = load(matfile);
    try
        mask.hdr = spm_vol([II.I.OutputDir filesep 'mask.nii']);
    catch
        [p mf] = fileparts(im);
        mask.hdr = spm_vol([p filesep 'mask.nii']);
    end
    mask.data = spm_read_vols(mask.hdr);
    img.hdr = spm_vol(im);
    img.data = spm_read_vols(img.hdr);
    tmp = img.hdr.descrip; i1 = find(tmp=='['); i2 = find(tmp==']');
    df = str2num(tmp(i1(1)+1:i2(1)-1));
    df = [1 df];    
    n = 1;
    FWHM = II.I.FWHM{1};
    R = spm_resels_vol(mask.hdr,FWHM)';
    SS = sum(mask.data(:)==1);
    M = II.I.v.mat;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHMmm= FWHM.*VOX; % FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM)));% voxels to resels

else % SPM
    
    SPM = load(matfile);
    SPM = SPM.SPM;
    df   = [1 SPM.xX.erdf];
    STAT = 'T';
    n    = 1;
    R    = SPM.xVol.R;
    SS    = SPM.xVol.S;
    M    = SPM.xVol.M;
    VOX  = sqrt(diag(M(1:3,1:3)'*M(1:3,1:3)))';
    FWHM = SPM.xVol.FWHM;
    FWHMmm= FWHM.*VOX; 				% FWHM {mm}
    v2r  = 1/prod(FWHM(~isinf(FWHM))); %-voxels to resels
    
end
if ~nargout
    sf_ShowVolInfo(R,SS,VOX,FWHM,FWHMmm)
end
epsP = alpha*epsP;
Status = 'OK';
if u <= 1; u = spm_u(u,df,STAT); end

if length(range)==1 & ~isnan(range)
  
  %
  % Dummy case... just report P-value
  %

  k  = range;
  Pc = spm_P(1,k*v2r,u,df,STAT,R,n,SS);
  
  Status = 'JustPvalue';

elseif (spm_P(1,1*v2r,u,df,STAT,R,n,SS)<alpha)

  %
  % Crazy setting, where 1 voxel cluster is significant
  %

  k = 1;
  Pc = spm_P(1,1*v2r,u,df,STAT,R,n,SS);
  Status = 'TooRough';

elseif isnan(range)

  %
  % Automated search
  % 

  % Initial (lower bound) guess is the expected number of voxels per cluster
  [P Pn Em En EN] = spm_P(1,0,u,df,STAT,R,n,SS);
  kr = En; % Working in resel units
  rad = (kr)^(1/3); % Parameterize proportional to cluster diameter

  %
  % Crude linear search bound answer
  %
  Pcl  = 1;   % Lower bound on P
  radu = rad; % Upper bound on rad
  Pcu  = 0;   % Upper bound on P
  radl = Inf; % Lower bound on rad
  while (Pcl > alpha)
    Pcu  = Pcl;
    radl = radu; % Save previous result
    radu = radu*1.1;
    Pcl  = spm_P(1,radu^3   ,u,df,STAT,R,n,SS);
  end

  %
  % Newton-Rhapson refined search
  %
  d = 1;		    
  os = NaN;     % Old sign
  ms = (radu-radl)/10;  % Max step
  du = ms/100;
  % Linear interpolation for initial guess
  rad = radl*(alpha-Pcl)/(Pcu-Pcl)+radu*(Pcu-alpha)/(Pcu-Pcl);
  iter = 1;
  while abs(d) > epsP
    Pc  = spm_P(1,rad^3   ,u,df,STAT,R,n,SS);
    Pc1 = spm_P(1,(rad+du)^3,u,df,STAT,R,n,SS);
    d   = (alpha-Pc)/((Pc1-Pc)/du);
    os = sign(d);  % save old sign
    % Truncate search if step is too big
    if abs(d)>ms, 
      d = sign(d)*ms;
    end
    % Keep inside the given range
    if (rad+d)>radu, d = (radu-rad)/2; end
    if (rad+d)<radl, d = (rad-radl)/2; end
    % update
    rad = rad + d;
    iter = iter+1;
    if (iter>=maxi), 
      Status = 'TooManyIter';
      break; 
    end
  end
  % Convert back
  kr = rad^3;
  k = ceil(kr/v2r);
  Pc  = spm_P(1,k*v2r,u,df,STAT,R,n,SS);

%
% Brute force!
%
else
  Pc = 1;
  for k = range
    Pc = spm_P(1,k*v2r,u,df,STAT,R,n,SS);
    %fprintf('k=%d Pc=%g\n',k,Pc);
    if Pc <= alpha, 
      break; 
    end
  end;
  if (Pc > alpha)
    Status = 'OutOfRange';
  end
end
if ~nargout
    switch (Status)
     case {'JustPvalue'}
      fprintf(['  For a cluster-defining threshold of %0.4f a cluster size threshold of\n'...
           '  %d has corrected P-value %g\n\n'],...
          u,k,Pc);
     case {'OK'}
      fprintf(['  For a cluster-defining threshold of %0.4f the level %0.3f corrected\n'...
           '  cluster size threshold is %d and has size (corrected P-value) %g\n\n'],...
          u,alpha,k,Pc);
     case 'TooRough'
      fprintf(['\n  WARNING: Single voxel cluster is significant!\n\n',...
               '  For a cluster-defining threshold of %0.4f a k=1 voxel cluster\n'...
           '  size threshold has size (corrected P-value) %g\n\n'],...
          u,Pc); 
     case 'TooManyIter'
      fprintf(['\n  WARNING: Automated search failed to converge\n' ...
           '  Try systematic search.\n\n']); 
     case 'OutOfRange'  
      fprintf(['\n  WARNING: Within the range of cluster sizes searched (%g...%g)\n',...
             '  a corrected P-value <= alpha was not found (smallest P: %g)\n\n'],...
          range(1),range(end),Pc); 
      fprintf([  '  Try increasing the range or an automatic search.\n\n']); 
     otherwise
      error('Unknown status code');
    end
end
extent = k;
info.image = im;
info.extent = k;
info.alpha = alpha;
info.u = u;
info.Pc = Pc;
function [out, outmat] = reslice_image(in, ref, int)
    % Most of the code is adapted from rest_Reslice in REST toolbox:
    % Written by YAN Chao-Gan 090302 for DPARSF. Referenced from spm_reslice.
    % State Key Laboratory of Cognitive Neuroscience and Learning 
    % Beijing Normal University, China, 100875
    if nargin<3, int = 1; end
    if nargin<2, display('USAGE: [out, outmat] = reslice_image(infile, ref, SourceHead, int)'); return; end
    if iscell(ref), ref = char(ref); end
    if iscell(in), in = char(in); end
    % read in reference image
    RefHead = spm_vol(ref); 
    mat=RefHead.mat;
    dim=RefHead.dim;
    SourceHead = spm_vol(in);
    [x1,x2,x3] = ndgrid(1:dim(1),1:dim(2),1:dim(3));
    d       = [int*[1 1 1]' [1 1 0]'];
    C       = spm_bsplinc(SourceHead, d);
    v       = zeros(dim);
    M       = inv(SourceHead.mat)*mat; % M = inv(mat\SourceHead.mat) in spm_reslice.m
    y1      = M(1,1)*x1+M(1,2)*x2+(M(1,3)*x3+M(1,4));
    y2      = M(2,1)*x1+M(2,2)*x2+(M(2,3)*x3+M(2,4));
    y3      = M(3,1)*x1+M(3,2)*x2+(M(3,3)*x3+M(3,4));
    out     = spm_bsplins(C, y1,y2,y3, d);
    tiny = 5e-2; % From spm_vol_utils.c
    Mask = true(size(y1));
    Mask = Mask & (y1 >= (1-tiny) & y1 <= (SourceHead.dim(1)+tiny));
    Mask = Mask & (y2 >= (1-tiny) & y2 <= (SourceHead.dim(2)+tiny));
    Mask = Mask & (y3 >= (1-tiny) & y3 <= (SourceHead.dim(3)+tiny));
    out(~Mask) = 0;
    outmat = mat;

% | MISC UTILITIES
% =========================================================================
function flag   = check4design
    global st
    flag = 0; 
    if ~exist(fullfile(fileparts(st.ol.fname), 'I.mat'),'file') & ~exist(fullfile(fileparts(st.ol.fname), 'SPM.mat'),'file') 
        flag = 1; 
        printmsg('No SPM.mat or I.mat - Disabling threshold correction', 'WARNING');
        set(findobj(st.fig, 'Tag', 'Correction'), 'Enable', 'off'); 
    else
        set(findobj(st.fig, 'Tag', 'Correction'), 'Enable', 'on'); 
    end
function str    = nicetime
    str = strtrim(datestr(now,'HH:MM:SS PM on mmm. DD, YYYY'));
function outmsg = printmsg(msg, msgtitle, msgborder, msgwidth, hideoutput)
% PRINTMSG Create and print a formatted message with title
%
%	USAGE: fmtmessage = printmsg(message, msgtitle, msgborder, msgwidth)
%
%

% --------------------------- Copyright (C) 2014 ---------------------------
%	Author: Bob Spunt
%	Email: bobspunt@gmail.com
% 
%	$Created: 2014_09_27
% _________________________________________________________________________
if nargin<5, hideoutput = 0; end
if nargin<4, msgwidth   = 75; end
if nargin<3, msgborder  = {'_' '_'}; end
if nargin<2, msgtitle   = ''; end
if nargin<1,
    msg = 'USAGE: fmtmessage = printmsg(msg, [msgtitle], [msgborder], [msgwidth])';
    msgtitle = 'I NEED MORE INPUT FROM YOU';
end
if ischar(msgborder), msgborder = cellstr(msgborder); end
if length(msgborder)==1, msgborder = [msgborder msgborder]; end
if iscell(msg), msg = char(msg); end
if iscell(msgtitle), msgtitle = char(msgtitle); end
msgtop          = repmat(msgborder{1},1,msgwidth);
msgbottom       = repmat(msgborder{2},1,msgwidth);
if ~isempty(msgtitle), msgtitle = sprintf('%s %s %s', msgborder{1}, strtrim(msgtitle), msgborder{1}); end
titleln         = length(msgtitle);
msgln           = length(msg); 
msgtop(floor(.5*msgwidth-.5*titleln):floor(.5*msgwidth-.5*titleln) + titleln-1) = msgtitle;
outmsg      = repmat(' ', 1, msgwidth);
outmsg(floor(.5*msgwidth-.5*msgln):floor(.5*msgwidth-.5*msgln) + msgln-1) = msg;
outmsg      = sprintf('%s\n\n%s\n%s', msgtop, outmsg, msgbottom);
if ~hideoutput, disp(outmsg); end
function out    = abridgepath(str, maxchar)
if nargin<2, maxchar =  85; end
if iscell(str), str = char(str); end
if length(str) <= maxchar, out = str; return; end
s   = regexp(str, filesep, 'split');
s(cellfun('isempty', s)) = [];
p1 = fullfile(s{1}, '...'); 
s(1) = []; 
badpath = 1;
count = 0; 
while badpath
    count = count + 1; 
    testpath = s; 
    testpath(1:count) = []; 
    testpath = fullfile(p1, testpath{:}); 
    if length(testpath)<=maxchar, badpath = 0; end
end
out = testpath; 
function out    = cmap_upsample(in, N)
    num = size(in,1);
    ind = repmat(1:num, ceil(N/num), 1);
    rem = numel(ind) - N; 
    if rem, ind(end,end-rem+1:end) = NaN; end
    ind = ind(:); ind(isnan(ind)) = [];
    out = in(ind(:),:);
function vol    = uigetvol(message, multitag)
    % UIGETVOL Dialogue for selecting image volume file
    %
    %   USAGE: vol = uigetvol(message, multitag)
    %       
    %       message = to display to user
    %       multitag = (default = 0) tag to allow selecting multiple images
    %
    % EX: img = uigetvol('Select Image to Process'); 
    %
    if nargin < 2, multitag = 0; end
    if nargin < 1, message = 'Select Image File'; end
    if ~multitag
        [imname, pname] = uigetfile({'*.img; *.nii; *.nii.gz', 'Image File'; '*.*', 'All Files (*.*)'}, message);
    else
        [imname, pname] = uigetfile({'*.img; *.nii', 'Image File'; '*.*', 'All Files (*.*)'}, message, 'MultiSelect', 'on');
    end
    if isequal(imname,0) || isequal(pname,0)
        vol = [];
    else
        vol = fullfile(pname, strcat(imname));
    end
function vol    = uiputvol(defname, prompt)
    if nargin < 1, defname = 'myimage.nii'; end
    if nargin < 2, prompt = 'Save image as'; end
    [imname, pname] = uiputfile({'*.img; *.nii', 'Image File'; '*.*', 'All Files (*.*)'}, prompt, defname);
    if isequal(imname,0) || isequal(pname,0)
        vol = [];
    else
        vol = fullfile(pname, imname); 
    end
function out    = cellnum2str(in, ndec)
% NEW2PVAL Convert numeric array of p-values to formatted cell array of p-values
%
%  USAGE: out = num2pval(in)
% __________________________________________________________________________
%  INPUTS
%	in: numeric array of p-values
%   ndec: number of decimal points to display
%

% ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
%	Created:  2015-01-13
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 2, ndec = 2; end
if nargin < 1, disp('USAGE: out = num2pval(in)'); return; end
if ~iscell(in), error('Input array must be cell!'); end
n   = cell2mat(in); 
out = cellfun(@sprintf, repmat({['%2.' num2str(ndec) 'f']}, size(in)), in, 'Unif', false); 
out = regexprep(out, '0\.', '\.');
out(mod(n,1)==0) = cellfun(@num2str, in(mod(n,1)==0), 'unif', false);
function out    = adjustbrightness(in)
    lim = .5;
    dat.min = min(in(in>0)); 
    dat.max = max(in(in>0));
    dat.dim = size(in);
    out = double(in)./255; 
    out(out>0) = out(out>0) + (lim-nanmean(nanmean(out(out>0))))*(1 - out(out>0)); 
    out(out>0) = scaledata(out(out>0), [dat.min dat.max]);
function fn     = construct_filename
    global st
    [p,n]   = fileparts(st.ol.hdr.fname);
    idx     = regexp(st.ol.descrip, ': ');
    if ~isempty(idx)
        n = strtrim(st.ol.descrip(idx+1:end));
        n = regexprep(n, ' ', '_'); 
    end
    fn = sprintf('%s/%s_x=%d_y=%d_z=%d.png', p, n, bspm_XYZreg('RoundCoords',st.centre,st.ol.M,st.ol.DIM));        
function s      = easydefaults(varargin)
% easydefaults  Set many default arguments quick and easy.
%
%   - For input arguments x1,x2,x3, set default values x1def,x2def,x3def
%     using easydefaults as parameter-value pairs:
%       easydefaults('x1',x1def,'x2',x2def,'x3',x3def);
%   
%   - Defaults can be set for any input argument, whether explicit or as 
%     part of a parameter-value pair:
%       function dummy_function(x,varargin)
%           easydefaults('x',1,'y',2);
%           ...   
%       end
%
%   - easydefaults and easyparse can in principle be used in either order, 
%     but it is usually better to parse first and fill in defaults after:
%       function dummy_function(x,varargin)
%           easyparse(varargin,'y')
%           easydefaults('x',1,'y',2);
%           ...   
%       end
%
%   CAVEAT UTILITOR: this function relies on evals and assignin statements.
%   Input checking is performed to limit potential damage, but use at your 
%   own risk.
%
%   Author: Jared Schwede 
%   Last update: Jan 14, 2013

    % Check that all inputs come in parameter-value pairs.
    if mod(length(varargin),2)
        error('Default arguments must be specified in pairs!');
    end
    
    for i=1:2:length(varargin)
        if ~ischar(varargin{i})
            error('Variables to easydefaults must be written as strings!');
        end
        
        % We'll check that the varargin is a valid variable name. This
        % should hopefully avoid any nasty code...
        if ~isvarname(varargin{i})
            error('Invalid variable name!');
        end
        
        if exist(varargin{i},'builtin') || (exist(varargin{i},'file') == 2) || exist(varargin{i},'class')
            warning('MATLAB:defined_function',['''' varargin{i} ''' conflicts with the name of a function, m-file, or class along the MATLAB path and will be ignored by easydefaults.' ...
                                        ' Please rename the variable, or use a temporary variable with easydefaults and explicitly define ''' varargin{i} ...
                                        ''' within your function.']);
        else
            if ~evalin('caller',['exist(''' varargin{i} ''',''var'')'])
                % We assign the arguments to a struct, s, which allows us to
                % check that the evalin statement will not either throw an 
                % error or execute some nasty code.
                s.(varargin{i}) = varargin{i+1};
                assignin('caller',varargin{i},varargin{i+1});
            end
        end
end
function s      = easyparse(caller_varargin,allowed_names)
% easyparse    Parse parameter-value pairs without using inputParser
%   easyparse is called by a function which takes parameter value pairs and
%   creates individual variables in that function. It can also be used to
%   generate a struct like inputParser.
%
%   - To create variables in the function workspace according to the
%     varargin of parameter-value pairs, use this syntax in your function:
%       easyparse(varargin)
%
%   - To create only variables with allowed_names, create a cell array of
%     allowed names and use this syntax:
%       easyparse(varargin, allowed_names);
%
%   - To create a struct with fields specified by the names in varargin,
%     (similar to the output of inputParser) ask for an output argument:
%       s = easyparse(...);
%  
%   CAVEAT UTILITOR: this function relies on assignin statements. Input
%   checking is performed to limit potential damage, but use at your own 
%   risk.
%
%   Author: Jared Schwede
%   Last update: January 14, 2013

    % We assume all inputs come in parameter-value pairs. We'll also assume
    % that there aren't enough of them to justify using a containers.Map. 
    for i=1:2:length(caller_varargin)
        if nargin == 2 && ~any(strcmp(caller_varargin{i},allowed_names))
            error(['Unknown input argument: ' caller_varargin{i}]);
        end
        
        if ~isvarname(caller_varargin{i})
            error('Invalid variable name!');
        end
        
        
        % We assign the arguments to the struct, s, which allows us to
        % check that the assignin statement will not either throw an error 
        % or execute some nasty code.
        s.(caller_varargin{i}) = caller_varargin{i+1};
        % ... but if we ask for the struct, don't write all of the
        % variables to the function as well.
        if ~nargout
            if exist(caller_varargin{i},'builtin') || (exist(caller_varargin{i},'file') == 2) || exist(caller_varargin{i},'class')
                warning('MATLAB:defined_function',['''' caller_varargin{i} ''' conflicts with the name of a function, m-file, or class along the MATLAB path and will be ignored by easyparse.' ...
                                            ' Please rename the variable, or use a temporary variable with easyparse and explicitly define ''' caller_varargin{i} ...
                                            ''' within your function.']);
            else
                assignin('caller',caller_varargin{i},caller_varargin{i+1});
            end
        end
    end
function out    = scaledata(in, minmax)
% SCALEDATA
%
% USAGE: out = scaledata(in, minmax)
%
% Example:
% a = [1 2 3 4 5];
% a_out = scaledata(a,0,1);
% 
% Output obtained: 
%            0    0.1111    0.2222    0.3333    0.4444
%       0.5556    0.6667    0.7778    0.8889    1.0000
%
% Program written by:
% Aniruddha Kembhavi, July 11, 2007
if nargin<2, minmax = [0 1]; end
if nargin<1, error('USAGE: out = scaledata(in, minmax)'); end
out = in - repmat(min(in), size(in, 1), 1); 
out = ((out./repmat(range(out), size(out,1), 1))*(minmax(2)-minmax(1))) + minmax(1); 
function answer = yesorno(question, titlestr)
% YESORNO Ask Yes/No Question
%
%  USAGE: h = yesorno(question, *titlestr)    *optional input
% __________________________________________________________________________
%  INPUTS
%   question: character array to present to user 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-09-30
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: h = yesorno(question, *titlestr)'); return; end
if nargin < 2, titlestr = 'Yes or No?'; end
if iscell(titlestr), titlestr = char(titlestr); end
if iscell(question), question = char(question); end
global answer
answer = []; 
h(1) = figure(...
    'Units', 'norm', ...
    'WindowStyle', 'modal', ...
    'Position',[.425 .45 .15 .10],...
    'Resize','off',...
    'Color', [0.8941    0.1020    0.1098]*.60, ...
    'NumberTitle','off',...
    'DockControls','off',...
    'Tag', 'yesorno', ...
    'MenuBar','none',...
    'Name',titlestr,...
    'Visible','on',...
    'Toolbar','none');
h(2) = uicontrol('parent', h(1), 'units', 'norm', 'style',  'text', 'backg', [0.8941    0.1020    0.1098]*.60,'foreg', [248/255 248/255 248/255], 'horiz', 'center', ...
    'pos', [.075 .40 .850 .500], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 15, 'string', question, 'visible', 'on'); 
h(3) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
'pos', [.25 .10 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 16, 'string', 'Yes', 'visible', 'on', 'callback', {@cb_answer, h});
h(4) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
'pos', [.55 .10 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 16, 'string', 'No', 'visible', 'on', 'callback', {@cb_answer, h});
uiwait(h(1)); 
function cb_answer(varargin)
    global answer
    answer = get(varargin{1}, 'string');
    delete(findobj(0, 'Tag', 'yesorno'));
function [flag, h] = waitup(msg, titlestr)
% YESORNO Ask Yes/No Question
%
%  USAGE: h = yesorno(question, *titlestr)    *optional input
% __________________________________________________________________________
%  INPUTS
%   question: character array to present to user 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-09-30
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: [flag, h] = waitup(msg, titlestr)'); return; end
if nargin < 2, titlestr = 'Please Wait'; end
if iscell(titlestr), titlestr = char(titlestr); end
if iscell(msg), msg = char(msg); end
global flag
flag = []; 
h(1) = figure(...
    'Units', 'norm', ...
    'WindowStyle', 'modal', ...
    'Position',[.425 .45 .15 .10],...
    'Resize','off',...
    'Color', [0.8941    0.1020    0.1098]*.60, ...
    'NumberTitle','off',...
    'DockControls','off',...
    'Tag', 'waitup', ...
    'MenuBar','none',...
    'Name',titlestr,...
    'Visible','on',...
    'Toolbar','none');
h(2) = uicontrol('parent', h(1), 'units', 'norm', 'style',  'text', 'backg', [0.8941    0.1020    0.1098]*.60,'foreg', [248/255 248/255 248/255], 'horiz', 'center', ...
    'pos', [.075 .40 .850 .525], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 15, 'string', msg, 'visible', 'on'); 
h(3) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
'pos', [.35 .10 .30 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 16, 'string', 'Cancel', 'visible', 'on', 'callback', {@cb_cancel, h});
uiwait(h(1)); 
function cb_cancel(varargin)
    global flag
    flag = get(varargin{1}, 'string');
    delete(findobj(0, 'Tag', 'waitup'));
function h      = headsup(msg, titlestr, wait4resp)
% HEADSUP Present message to user and wait for a response
%
%  USAGE: h = headsup(msg, *titlestr, *wait4resp)    *optional input
% __________________________________________________________________________
%  INPUTS
%   msg: character array to present to user 
%

% ---------------------- Copyright (C) 2014 Bob Spunt ----------------------
%	Created:  2014-09-30
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 1, disp('USAGE: h = headsup(msg, *titlestr, *wait4resp)'); return; end
if nargin < 2, titlestr = 'Heads Up'; end
if nargin < 3, wait4resp = 1; end
if iscell(msg), msg = char(msg); end
if iscell(titlestr), titlestr = char(titlestr); end
h(1) = figure(...
    'Units', 'norm', ...
    'WindowStyle', 'modal', ...
    'Position',[.425 .45 .15 .10],...
    'Resize','off',...
    'Color', [0.8941    0.1020    0.1098]*.60, ...
    'NumberTitle','off',...
    'DockControls','off',...
    'Tag', 'headsup', ...
    'MenuBar','none',...
    'Name',titlestr,...
    'Visible','on',...
    'Toolbar','none');
h(2) = uicontrol('parent', h(1), 'units', 'norm', 'style',  'text', 'backg', [0.8941    0.1020    0.1098]*.60,'foreg', [248/255 248/255 248/255], 'horiz', 'center', ...
    'pos', [.075 .40 .850 .500], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 15, 'string', msg, 'visible', 'on'); 
if wait4resp
    h(3) = uicontrol('parent', h(1), 'units', 'norm', 'style', 'push', 'foreg', [0 0 0], 'horiz', 'center', ...
    'pos', [.4 .10 .2 .30], 'fontname', 'arial', 'fontw', 'bold', 'fontsize', 16, 'string', 'OK', 'visible', 'on', 'callback', {@cb_ok, h});
    uiwait(h(1)); 
end
drawnow; 
function cb_ok(varargin)
    delete(findobj(0, 'Tag', 'headsup'));
    drawnow; 
function p      = bob_t2p(t, df)
% BOB_T2P Get p-value from t-value + df
%
%   ARGUMENTS
%       t = t-value
%       df = degrees of freedom
%
    p = spm_Tcdf(t, df);
    p = 1 - p;
function y      = range(x)
y = nanmax(x) - nanmin(x); 
function writereport(incell, outname)
% WRITEREPORT Write cell array to CSV file
%
%  USAGE: outname = writereport(incell, outname)	*optional input
% __________________________________________________________________________
%  INPUTS
%	incell:     cell array of character arrays
%	outname:   base name for output csv file 
%

% ---------------------- Copyright (C) 2015 Bob Spunt ----------------------
%	Created:  2015-02-02
%	Email:    spunt@caltech.edu
% __________________________________________________________________________
if nargin < 2, disp('USAGE: outname = writereport(incell, outname)'); return; end

% | Convert all cell contents to character arrays
% | ========================================================================
[nrow, ncol] = size(incell);
for i = 1:numel(incell)
    if isnumeric(incell{i}), incell{i} = num2str(incell{i}); end
    if strcmp(incell{i},'NaN'), incell{i} = ''; end
end
incell = regexprep(incell, ',', '');

% | Write to file
% | ========================================================================
fid = fopen(outname,'w');
for r = 1:nrow
    fprintf(fid,['%s' repmat(',%s',1,ncol-1) '\n'],incell{r,:});
end
fclose(fid);
function mfile_showhelp(varargin)
% MFILE_SHOWHELP
%
% ------------------------------------------------------------------------
ST = dbstack('-completenames');
if isempty(ST), fprintf('\nYou must call this within a function\n\n'); return; end
eval(sprintf('help %s', ST(2).file));  
function save_error(err)
    global st
    errdata     = getReport(err);
    errlogname  = fullfile(fileparts(mfilename('fullpath')), 'ErrorMsg.txt'); 
    errmatname  = fullfile(fileparts(mfilename('fullpath')), 'ErrorDat.mat'); 
    errfigname  = fullfile(fileparts(mfilename('fullpath')), 'ErrorFig.fig');
    hgsave(errfigname); 
    eid         = fopen(errlogname, 'w');
    fwrite(eid, errdata);
    fclose(eid);
    save(errmatname, 'st');
    fprintf('\nERROR INFORMATION WRITTEN TO:\n\t%s\n\t%s\n\t%s\n\n', errlogname, errmatname, errfigname);
function arrayset(harray, propname, propvalue) 
% ARRAYGET Set property values for array of handles
%
% USAGE: arrayset(harray, propname, propvalue) 
%
% ==============================================
if nargin<2, error('USAGE: arrayset(harray, propname, propvalue) '); end
if size(harray, 1)==1, harray = harray'; end
if ~iscell(propvalue)
    arrayfun(@set, harray, repmat({propname}, length(harray), 1), ...
            repmat({propvalue}, length(harray), 1)); 
else
    if size(propvalue, 1)==1, propvalue = propvalue'; end
    arrayfun(@set, harray, repmat({propname}, length(harray), 1), propvalue); 
end

% | BSPM_OPTHVIEWS (MODIFIED FROM SPM8 SPM_OPTHVIEWS)
% =========================================================================
function varargout = bspm_orthviews(action,varargin)
% John Ashburner et al% Display orthogonal views of a set of images
% The basic fields of st are:
%         n        - the number of images currently being displayed
%         vols     - a cell array containing the data on each of the
%                    displayed images.
%         Space    - a mapping between the displayed images and the
%                    mm space of each image.
%         bb       - the bounding box of the displayed images.
%         centre   - the current centre of the orthogonal views
%         callback - a callback to be evaluated on a button-click.
%         xhairs   - crosshairs off/on
%         hld      - the interpolation method
%         fig      - the figure that everything is displayed in
%         mode     - the position/orientation of the sagittal view.
%                    - currently always 1
%
%         st.registry.hReg \_ See bspm_XYZreg for documentation
%         st.registry.hMe  /
%
% For each of the displayed images, there is a non-empty entry in the
% vols cell array.  Handles returned by "spm_orthviews('Image',.....)"
% indicate the position in the cell array of the newly created ortho-view.
% Operations on each ortho-view require the handle to be passed.
%
% When a new image is displayed, the cell entry contains the information
% returned by spm_vol (type help spm_vol for more info).  In addition,
% there are a few other fields, some of which are documented here:
%
%         premul  - a matrix to premultiply the .mat field by.  Useful
%                   for re-orienting images.
%         window  - either 'auto' or an intensity range to display the
%                   image with.
%         mapping - Mapping of image intensities to grey values. Currently
%                   one of 'linear', 'histeq', loghisteq',
%                   'quadhisteq'. Default is 'linear'.
%                   Histogram equalisation depends on the image toolbox
%                   and is only available if there is a license available
%                   for it.
%         ax      - a cell array containing an element for the three
%                   views.  The fields of each element are handles for
%                   the axis, image and crosshairs.
%
%         blobs   - optional.  Is there for using to superimpose blobs.
%                   vol     - 3D array of image data
%                   mat     - a mapping from vox-to-mm (see spm_vol, or
%                             help on image formats).
%                   max     - maximum intensity for scaling to.  If it
%                             does not exist, then images are auto-scaled.
%
%                   There are two colouring modes: full colour, and split
%                   colour.  When using full colour, there should be a
%                   'colour' field for each cell element.  When using
%                   split colourscale, there is a handle for the colorbar
%                   axis.
%
%                   colour  - if it exists it contains the
%                             red,green,blue that the blobs should be
%                             displayed in.
%                   cbar    - handle for colorbar (for split colourscale).
global st

persistent zoomlist reslist

if isempty(st), reset_st; end

if ~nargin, action = ''; end

if ~any(strcmpi(action,{'reposition','pos'}))
    spm('Pointer','Watch');
end
    
switch lower(action)
    case 'image'
        H = specify_image(varargin{1});
        
        if ~isempty(H)
            if numel(varargin)>=2
                st.vols{H}.area = varargin{2};
            else
                st.vols{H}.area = [0 0 1 1];
            end
            if isempty(st.bb), st.bb = maxbb; end
            resolution;
            bbox;
            cm_pos;
        end
        varargout{1} = H;
        mmcentre     = mean(st.Space*[maxbb';1 1],2)';
        st.centre    = mmcentre(1:3);
        redraw_all

    case 'caption'
        if ~isnumeric(varargin{1})
            varargin{1} = cellstr(varargin{1});
            xlh = NaN(numel(varargin{1}),1);
            for i=1:numel(varargin{1})
                h = bspm_orthviews('Caption',i,varargin{1}{i},varargin{3:end});
                if ~isempty(h), xlh(i) = h; end
            end
            varargout{1} = xlh;
            return;
        end
        
        vh = valid_handles(varargin{1});
        nh = numel(vh);
        
        xlh = nan(nh, 1);
        for i = 1:nh
            xlh(i) = get(st.vols{vh(i)}.ax{3}.ax, 'XLabel');
            if iscell(varargin{2})
                if i <= length(varargin{2})
                    set(xlh(i), 'String', varargin{2}{i});
                end
            else
                set(xlh(i), 'String', varargin{2});
            end
            for np = 4:2:nargin
                property = varargin{np-1};
                value = varargin{np};
                set(xlh(i), property, value);
            end
        end
        varargout{1} = xlh;
        
    case 'bb'
        if ~isempty(varargin) && all(size(varargin{1})==[2 3]), st.bb = varargin{1}; end
        bbox;
        redraw_all;
        
    case 'redraw'
        
        redraw_all;
        callback;
        if isfield(st,'registry')
            bspm_XYZreg('SetCoords',st.centre,st.registry.hReg,st.registry.hMe);
        end
        
    case 'reload_mats'
        if nargin > 1
            handles = valid_handles(varargin{1});
        else
            handles = valid_handles;
        end
        for i = handles
            fnm = spm_file(st.vols{i}.fname, 'number', st.vols{i}.n);
            st.vols{i}.mat = spm_get_space(fnm);
        end
        
    case 'reposition'

        if isempty(varargin), tmp = findcent;
        else tmp = varargin{1}; end
        if numel(tmp) == 3
            if isequal(round(tmp),round(st.centre)), return; end
            st.centre = tmp(1:3);
        end
        redraw_all;
        callback;
        cm_pos;
        setvoxelinfo;
        if isfield(st,'registry')
            bspm_XYZreg('SetCoords',st.centre,st.registry.hReg,st.registry.hMe);
        end
        drawnow; 
        
    case 'setcoords'
        st.centre = varargin{1};
        st.centre = st.centre(:);
        redraw_all;
        callback;
        cm_pos;
        
    case 'space'
        if numel(varargin) < 1
            st.Space = eye(4);
            st.bb = maxbb;
            resolution;
            bbox;
            redraw_all;
        else
            space(varargin{:});
            resolution;
            bbox;
            redraw_all;
        end
        
    case 'maxbb'
        st.bb = maxbb;
        bbox;
        redraw_all;
        
    case 'resolution'
        resolution(varargin{:});
        bbox;
        redraw_all;
        
    case 'window'
        if numel(varargin)<2
            win = 'auto';
        elseif numel(varargin{2})==2
            win = varargin{2};
        end
        for i=valid_handles(varargin{1})
            st.vols{i}.window = win;
        end
        redraw(varargin{1});
        
    case 'delete'
        my_delete(varargin{1});
        
    case 'move'
        move(varargin{1},varargin{2});
        % redraw_all;
        
    case 'reset'
        my_reset;
        
    case 'pos'
        if isempty(varargin)
            H = st.centre(:);
        else
            H = pos(varargin{1});
        end
        varargout{1} = H;
        
    case 'interp'
        st.hld = varargin{1};
        redraw_all;
        
    case 'xhairs'
        xhairs(varargin{:});
        
    case 'register'
        register(varargin{1});
        
    case 'addblobs'
        addblobs(varargin{:});
        % redraw(varargin{1});
        
    case 'setblobsmax'
        st.vols{varargin{1}}.blobs{varargin{2}}.max = varargin{3};
        bspm_orthviews('redraw')
    
    case 'setblobsmin'
        st.vols{varargin{1}}.blobs{varargin{2}}.min = varargin{3};
        bspm_orthviews('redraw')
        
    case 'addcolouredblobs'
        addcolouredblobs(varargin{:});
        % redraw(varargin{1});
        
    case 'addimage'
        addimage(varargin{1}, varargin{2});
        % redraw(varargin{1});
        
    case 'addcolouredimage'
        addcolouredimage(varargin{1}, varargin{2},varargin{3});
        % redraw(varargin{1});
        
    case 'addtruecolourimage'
        if nargin < 2
            varargin(1) = {1};
        end
        if nargin < 3
            varargin(2) = {spm_select(1, 'image', 'Image with activation signal')};
        end
        if nargin < 4
            actc = [];
            while isempty(actc)
                actc = getcmap(spm_input('Colourmap for activation image', '+1','s'));
            end
            varargin(3) = {actc};
        end
        if nargin < 5
            varargin(4) = {0.4};
        end
        if nargin < 6
            actv = spm_vol(varargin{2});
            varargin(5) = {max([eps maxval(actv)])};
        end
        if nargin < 7
            varargin(6) = {min([0 minval(actv)])};
        end
        
        addtruecolourimage(varargin{1}, varargin{2},varargin{3}, varargin{4}, ...
            varargin{5}, varargin{6});
        % redraw(varargin{1});
        
    case 'addcolourbar'
        addcolourbar(varargin{1}, varargin{2});
        
    case {'removeblobs','rmblobs'}
        rmblobs(varargin{1});
        redraw(varargin{1});
        
    case 'addcontext'
        if nargin == 1
            handles = 1:max_img;
        else
            handles = varargin{1};
        end
        addcontexts(handles);
        
    case {'removecontext','rmcontext'}
        if nargin == 1
            handles = 1:max_img;
        else
            handles = varargin{1};
        end
        rmcontexts(handles);
        
    case 'context_menu'
        c_menu(varargin{:});
        
    case 'valid_handles'
        if nargin == 1
            handles = 1:max_img;
        else
            handles = varargin{1};
        end
        varargout{1} = valid_handles(handles);

    case 'zoom'
        zoom_op(varargin{:});
        
    case 'zoommenu'
        if isempty(zoomlist)
            zoomlist = [NaN 0 5    10  20 40 80 Inf];
            reslist  = [1   1 .125 .25 .5 .5 1  1  ];
        end
        if nargin >= 3
            if all(cellfun(@isnumeric,varargin(1:2))) && ...
                    numel(varargin{1})==numel(varargin{2})
                zoomlist = varargin{1}(:);
                reslist  = varargin{2}(:);
            else
                warning('bspm_orthviews:zoom',...
                        'Invalid zoom or resolution list.')
            end
        end
        if nargout > 0
            varargout{1} = zoomlist;
        end
        if nargout > 1
            varargout{2} = reslist;
        end
        
    otherwise
        addonaction = strcmpi(st.plugins,action);
        if any(addonaction)
            feval(['spm_ov_' st.plugins{addonaction}],varargin{:});
        end
end
spm('Pointer','Arrow');
function H  = specify_image(img)
global st
H = [];
if isstruct(img)
    V = img(1);
else
    try
        V = spm_vol(img);
    catch
        fprintf('Can not use image "%s"\n', img);
        return;
    end
end
if numel(V)>1, V=V(1); end

ii = 1;
while ~isempty(st.vols{ii}), ii = ii + 1; end
DeleteFcn = ['spm_orthviews(''Delete'',' num2str(ii) ');'];
V.ax = cell(3,1);
for i=1:3
    ax = axes('Visible','off', 'Parent', st.figax, ...
        'YDir','normal', 'DeleteFcn',DeleteFcn, 'ButtonDownFcn',@repos_start);
    d  = image(0, 'Tag','Transverse', 'Parent',ax, 'DeleteFcn',DeleteFcn);
    set(ax, 'Ydir','normal', 'ButtonDownFcn', @repos_start);
    lx = line(0,0, 'Parent',ax, 'DeleteFcn',DeleteFcn, 'Color',[0 0 1]);
    ly = line(0,0, 'Parent',ax, 'DeleteFcn',DeleteFcn, 'Color',[0 0 1]);
    if ~st.xhairs
        set(lx, 'Visible','off');
        set(ly, 'Visible','off');
    end
    V.ax{i} = struct('ax',ax,'d',d,'lx',lx,'ly',ly);
end
V.premul    = eye(4);
V.window    = 'auto';
V.mapping   = 'linear';
st.vols{ii} = V;
H = ii;
function bb = maxbb
global st
mn = [Inf Inf Inf];
mx = -mn;
for i=valid_handles
    premul = st.Space \ st.vols{i}.premul;
    bb = spm_get_bbox(st.vols{i}, 'fv', premul);
    mx = max([bb ; mx]);
    mn = min([bb ; mn]);
end
bb = [mn ; mx];
function H  = pos(handle)
global st
H = [];
for i=valid_handles(handle)
    is = inv(st.vols{i}.premul*st.vols{i}.mat);
    H = is(1:3,1:3)*st.centre(:) + is(1:3,4);
end
function mx = maxval(vol)
if isstruct(vol)
    mx = -Inf;
    for i=1:vol.dim(3)
        tmp = spm_slice_vol(vol,spm_matrix([0 0 i]),vol.dim(1:2),0);
        imx = max(tmp(isfinite(tmp)));
        if ~isempty(imx), mx = max(mx,imx); end
    end
else
    mx = max(vol(isfinite(vol)));
end
function mn = minval(vol)
if isstruct(vol)
    mn = Inf;
    for i=1:vol.dim(3)
        tmp = spm_slice_vol(vol,spm_matrix([0 0 i]),vol.dim(1:2),0);
        imn = min(tmp(isfinite(tmp)));
        if ~isempty(imn), mn = min(mn,imn); end
    end
else
    mn = min(vol(isfinite(vol)));
end
function m  = max_img
m = 24;
function centre = findcent
    global st
    obj    = get(st.fig,'CurrentObject');
    centre = [];
    cent   = [];
    cp     = [];
    for i=valid_handles
        for j=1:3
            if ~isempty(obj)
                if (st.vols{i}.ax{j}.ax == obj),
                    cp = get(obj,'CurrentPoint');
                end
            end
            if ~isempty(cp)
                cp   = cp(1,1:2);
                is   = inv(st.Space);
                cent = is(1:3,1:3)*st.centre(:) + is(1:3,4);
                switch j
                    case 1
                        cent([1 2])=[cp(1)+st.bb(1,1)-1 cp(2)+st.bb(1,2)-1];
                    case 2
                        cent([1 3])=[cp(1)+st.bb(1,1)-1 cp(2)+st.bb(1,3)-1];
                    case 3
                        if st.mode ==0
                            cent([3 2])=[cp(1)+st.bb(1,3)-1 cp(2)+st.bb(1,2)-1];
                        else
                            cent([2 3])=[st.bb(2,2)+1-cp(1) cp(2)+st.bb(1,3)-1];
                        end
                end
                break;
            end
        end
        if ~isempty(cent), break; end
    end
    if ~isempty(cent), centre = st.Space(1:3,1:3)*cent(:) + st.Space(1:3,4); end
function handles = valid_handles(handles)
    global st
    if ~nargin, handles = 1:max_img; end
    if isempty(st) || ~isfield(st,'vols')
        handles = [];
    elseif ~ishandle(st.fig)
        handles = []; 
    else
        handles = handles(:)';
        handles = handles(handles<=max_img & handles>=1 & ~rem(handles,1));
        for h=handles
            if isempty(st.vols{h}), handles(handles==h)=[]; end
        end
    end
function img = scaletocmap(inpimg,mn,mx,cmap,miscol)
if nargin < 5, miscol=1; end
cml = size(cmap,1);
scf = (cml-1)/(mx-mn);
img = round((inpimg-mn)*scf)+1;
img(img<1)   = 1;
img(img>cml) = cml;
img(~isfinite(img)) = miscol;
function item_parent = addcontext(volhandle)
global st
% create context menu
set(0,'CurrentFigure',st.fig);
% contextmenu
item_parent = uicontextmenu;

% contextsubmenu 0
item00 = uimenu(item_parent, 'Label','unknown image', 'UserData','filename');
bspm_orthviews('context_menu','image_info',item00,volhandle);
item0a = uimenu(item_parent, 'UserData','pos_mm', 'Separator','on', ...
    'Callback','bspm_orthviews(''context_menu'',''repos_mm'');');
item0b = uimenu(item_parent, 'UserData','pos_vx', ...
    'Callback','bspm_orthviews(''context_menu'',''repos_vx'');');
item0c = uimenu(item_parent, 'UserData','v_value');

% contextsubmenu 1
item1    = uimenu(item_parent,'Label','Zoom', 'Separator','on');
[zl, rl] = bspm_orthviews('ZoomMenu');
for cz = numel(zl):-1:1
    if isinf(zl(cz))
        czlabel = 'Full Volume';
    elseif isnan(zl(cz))
        czlabel = 'BBox, this image > ...';
    elseif zl(cz) == 0
        czlabel = 'BBox, this image nonzero';
    else
        czlabel = sprintf('%dx%d mm', 2*zl(cz), 2*zl(cz));
    end
    item1_x = uimenu(item1, 'Label',czlabel,...
        'Callback', sprintf(...
        'bspm_orthviews(''context_menu'',''zoom'',%d,%d)',zl(cz),rl(cz)));
    if isinf(zl(cz)) % default display is Full Volume
        set(item1_x, 'Checked','on');
    end
end

% contextsubmenu 2
checked   = {'off','off'};
checked{st.xhairs+1} = 'on';
item2     = uimenu(item_parent,'Label','Crosshairs','Callback','bspm_orthviews(''context_menu'',''Xhair'');','Checked',checked{2});

% contextsubmenu 3
if st.Space == eye(4)
    checked = {'off', 'on'};
else
    checked = {'on', 'off'};
end
item3     = uimenu(item_parent,'Label','Orientation');
item3_1   = uimenu(item3,      'Label','World space', 'Callback','bspm_orthviews(''context_menu'',''orientation'',3);','Checked',checked{2});
item3_2   = uimenu(item3,      'Label','Voxel space (1st image)', 'Callback','bspm_orthviews(''context_menu'',''orientation'',2);','Checked',checked{1});
item3_3   = uimenu(item3,      'Label','Voxel space (this image)', 'Callback','bspm_orthviews(''context_menu'',''orientation'',1);','Checked','off');

% contextsubmenu 3
if isempty(st.snap)
    checked = {'off', 'on'};
else
    checked = {'on', 'off'};
end
item3     = uimenu(item_parent,'Label','Snap to Grid');
item3_1   = uimenu(item3,      'Label','Don''t snap', 'Callback','bspm_orthviews(''context_menu'',''snap'',3);','Checked',checked{2});
item3_2   = uimenu(item3,      'Label','Snap to 1st image', 'Callback','bspm_orthviews(''context_menu'',''snap'',2);','Checked',checked{1});
item3_3   = uimenu(item3,      'Label','Snap to this image', 'Callback','bspm_orthviews(''context_menu'',''snap'',1);','Checked','off');

% contextsubmenu 4
if st.hld == 0
    checked = {'off', 'off', 'on'};
elseif st.hld > 0
    checked = {'off', 'on', 'off'};
else
    checked = {'on', 'off', 'off'};
end
item4     = uimenu(item_parent,'Label','Interpolation');
item4_1   = uimenu(item4,      'Label','NN',    'Callback','bspm_orthviews(''context_menu'',''interpolation'',3);', 'Checked',checked{3});
item4_2   = uimenu(item4,      'Label','Trilin', 'Callback','bspm_orthviews(''context_menu'',''interpolation'',2);','Checked',checked{2});
item4_3   = uimenu(item4,      'Label','Sinc',  'Callback','bspm_orthviews(''context_menu'',''interpolation'',1);','Checked',checked{1});

% contextsubmenu 5
% item5     = uimenu(item_parent,'Label','Position', 'Callback','bspm_orthviews(''context_menu'',''position'');');

% contextsubmenu 6
item6       = uimenu(item_parent,'Label','Image','Separator','on');
item6_1     = uimenu(item6,      'Label','Window');
item6_1_1   = uimenu(item6_1,    'Label','local');
item6_1_1_1 = uimenu(item6_1_1,  'Label','auto', 'Callback','bspm_orthviews(''context_menu'',''window'',2);');
item6_1_1_2 = uimenu(item6_1_1,  'Label','manual', 'Callback','bspm_orthviews(''context_menu'',''window'',1);');
item6_1_1_3 = uimenu(item6_1_1,  'Label','percentiles', 'Callback','bspm_orthviews(''context_menu'',''window'',3);');
item6_1_2   = uimenu(item6_1,    'Label','global');
item6_1_2_1 = uimenu(item6_1_2,  'Label','auto', 'Callback','bspm_orthviews(''context_menu'',''window_gl'',2);');
item6_1_2_2 = uimenu(item6_1_2,  'Label','manual', 'Callback','bspm_orthviews(''context_menu'',''window_gl'',1);');
if license('test','image_toolbox') == 1
    offon = {'off', 'on'};
    checked = offon(strcmp(st.vols{volhandle}.mapping, ...
        {'linear', 'histeq', 'loghisteq', 'quadhisteq'})+1);
    item6_2     = uimenu(item6,      'Label','Intensity mapping');
    item6_2_1   = uimenu(item6_2,    'Label','local');
    item6_2_1_1 = uimenu(item6_2_1,  'Label','Linear', 'Checked',checked{1}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''linear'');');
    item6_2_1_2 = uimenu(item6_2_1,  'Label','Equalised histogram', 'Checked',checked{2}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''histeq'');');
    item6_2_1_3 = uimenu(item6_2_1,  'Label','Equalised log-histogram', 'Checked',checked{3}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''loghisteq'');');
    item6_2_1_4 = uimenu(item6_2_1,  'Label','Equalised squared-histogram', 'Checked',checked{4}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping'',''quadhisteq'');');
    item6_2_2   = uimenu(item6_2,    'Label','global');
    item6_2_2_1 = uimenu(item6_2_2,  'Label','Linear', 'Checked',checked{1}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''linear'');');
    item6_2_2_2 = uimenu(item6_2_2,  'Label','Equalised histogram', 'Checked',checked{2}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''histeq'');');
    item6_2_2_3 = uimenu(item6_2_2,  'Label','Equalised log-histogram', 'Checked',checked{3}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''loghisteq'');');
    item6_2_2_4 = uimenu(item6_2_2,  'Label','Equalised squared-histogram', 'Checked',checked{4}, ...
        'Callback','bspm_orthviews(''context_menu'',''mapping_gl'',''quadhisteq'');');
end

% contextsubmenu 7
item7     = uimenu(item_parent,'Label','Overlay');
item7_1   = uimenu(item7,      'Label','Add blobs');
item7_1_1 = uimenu(item7_1,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_blobs'',2);');
item7_1_2 = uimenu(item7_1,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_blobs'',1);');
item7_2   = uimenu(item7,      'Label','Add image');
item7_2_1 = uimenu(item7_2,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_image'',2);');
item7_2_2 = uimenu(item7_2,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_image'',1);');
item7_3   = uimenu(item7,      'Label','Add coloured blobs','Separator','on');
item7_3_1 = uimenu(item7_3,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_c_blobs'',2);');
item7_3_2 = uimenu(item7_3,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_c_blobs'',1);');
item7_4   = uimenu(item7,      'Label','Add coloured image');
item7_4_1 = uimenu(item7_4,    'Label','local',  'Callback','bspm_orthviews(''context_menu'',''add_c_image'',2);');
item7_4_2 = uimenu(item7_4,    'Label','global', 'Callback','bspm_orthviews(''context_menu'',''add_c_image'',1);');
item7_5   = uimenu(item7,      'Label','Remove blobs',        'Visible','off','Separator','on');
item7_6   = uimenu(item7,      'Label','Remove coloured blobs','Visible','off');
item7_6_1 = uimenu(item7_6,    'Label','local', 'Visible','on');
item7_6_2 = uimenu(item7_6,    'Label','global','Visible','on');
item7_7   = uimenu(item7,      'Label','Set blobs max', 'Visible','off');

for i=1:3
    set(st.vols{volhandle}.ax{i}.ax,'UIcontextmenu',item_parent);
    st.vols{volhandle}.ax{i}.cm = item_parent;
end

% process any plugins
for k = 1:numel(st.plugins)
    feval(['spm_ov_', st.plugins{k}],'context_menu',volhandle,item_parent);
    if k==1
        h = get(item_parent,'Children');
        set(h(1),'Separator','on'); 
    end
end
function cm_handles = get_cm_handles
global st
cm_handles = [];
for i = valid_handles
    cm_handles = [cm_handles st.vols{i}.ax{1}.cm];
end
function addblobs(handle, xyz, t, mat, name)
global st
if nargin < 5
    name = '';
end
for i=valid_handles(handle)
    if ~isempty(xyz)
        rcp      = round(xyz);
        dim      = max(rcp,[],2)';
        off      = rcp(1,:) + dim(1)*(rcp(2,:)-1 + dim(2)*(rcp(3,:)-1));
        vol      = zeros(dim)+NaN;
        vol(off) = t;
        vol      = reshape(vol,dim);
        st.vols{i}.blobs=cell(1,1);
        mx = max([eps max(t)]);
        mn = min([0 min(t)]);
        st.vols{i}.blobs{1} = struct('vol',vol,'mat',mat,'max',mx, 'min',mn,'name',name);
        addcolourbar(handle,1);
    end
end
function addimage(handle, fname)
global st
for i=valid_handles(handle)
    if isstruct(fname)
        vol = fname(1);
    else
        vol = spm_vol(fname);
    end
    mat = vol.mat;
    st.vols{i}.blobs=cell(1,1);
    mx = max([eps maxval(vol)]);
    mn = min([0 minval(vol)]);
    st.vols{i}.blobs{1} = struct('vol',vol,'mat',mat,'max',mx,'min',mn);
    addcolourbar(handle,1);
end
function addcolouredblobs(handle, xyz, t, mat, colour, name)
if nargin < 6
    name = '';
end
global st
for i=valid_handles(handle)
    if ~isempty(xyz)
        rcp      = round(xyz);
        dim      = max(rcp,[],2)';
        off      = rcp(1,:) + dim(1)*(rcp(2,:)-1 + dim(2)*(rcp(3,:)-1));
        vol      = zeros(dim)+NaN;
        vol(off) = t;
        vol      = reshape(vol,dim);
        if ~isfield(st.vols{i},'blobs')
            st.vols{i}.blobs=cell(1,1);
            bset = 1;
        else
            bset = numel(st.vols{i}.blobs)+1;
        end
        mx = max([eps maxval(vol)]);
        mn = min([0 minval(vol)]);
        st.vols{i}.blobs{bset} = struct('vol',vol, 'mat',mat, ...
            'max',mx, 'min',mn, 'colour',colour, 'name',name);
    end
end
function addcolouredimage(handle, fname,colour)
global st
for i=valid_handles(handle)
    if isstruct(fname)
        vol = fname(1);
    else
        vol = spm_vol(fname);
    end
    mat = vol.mat;
    if ~isfield(st.vols{i},'blobs')
        st.vols{i}.blobs=cell(1,1);
        bset = 1;
    else
        bset = numel(st.vols{i}.blobs)+1;
    end
    mx = max([eps maxval(vol)]);
    mn = min([0 minval(vol)]);
    st.vols{i}.blobs{bset} = struct('vol',vol, 'mat',mat, ...
        'max',mx, 'min',mn, 'colour',colour);
end
function addtruecolourimage(handle,fname,colourmap,prop,mx,mn)
% adds true colour image to current displayed image
global st
for i=valid_handles(handle)
    if isstruct(fname)
        vol = fname(1);
    else
        vol = spm_vol(fname);
    end
    mat = vol.mat;
    if ~isfield(st.vols{i},'blobs')
        st.vols{i}.blobs=cell(1,1);
        bset = 1;
    else
        bset = numel(st.vols{i}.blobs)+1;
    end
    c = struct('cmap', colourmap,'prop',prop);
    st.vols{i}.blobs{bset} = struct('vol',vol, 'mat',mat, ...
        'max',mx, 'min',mn, 'colour',c);
    addcolourbar(handle,bset);
end
function addcontexts(handles)
for ii = valid_handles(handles)
    addcontext(ii);
end
bspm_orthviews('reposition',bspm_orthviews('pos'));
function rmblobs(handle)
global st
for i=valid_handles(handle)
    if isfield(st.vols{i},'blobs')
        for j=1:numel(st.vols{i}.blobs)
            if isfield(st.vols{i}.blobs{j},'cbar') && ishandle(st.vols{i}.blobs{j}.cbar),
                delete(st.vols{i}.blobs{j}.cbar);
            end
        end
        st.vols{i} = rmfield(st.vols{i},'blobs');
    end
end
function rmcontexts(handles)
global st
for ii = valid_handles(handles)
    for i=1:3
        set(st.vols{ii}.ax{i}.ax,'UIcontextmenu',[]);
        try, st.vols{ii}.ax{i} = rmfield(st.vols{ii}.ax{i},'cm'); end
    end
end
function register(hreg)
global st
%tmp = uicontrol('Position',[0 0 1 1],'Visible','off','Parent',st.fig);
h   = valid_handles;
if ~isempty(h)
    tmp = st.vols{h(1)}.ax{1}.ax;
    st.registry = struct('hReg',hreg,'hMe', tmp);
    bspm_XYZreg('Add2Reg',st.registry.hReg,st.registry.hMe, 'bspm_orthviews');
else
    warning('Nothing to register with');
end
st.centre = bspm_XYZreg('GetCoords',st.registry.hReg);
st.centre = st.centre(:);
function callback
global st
if ~iscell(st.callback), st.callback = { st.callback }; end
for i=1:numel(st.callback)
    if isa(st.callback{i},'function_handle')
        feval(st.callback{i});
    else
        eval(st.callback{i});
    end
end
function xhairs(state)
global st
if ~nargin, if st.xhairs, state = 'off'; else state = 'on'; end; end
st.xhairs = 0;
opt = 'on';
if ~strcmpi(state,'on')
    opt = 'off';
else
    st.xhairs = 1;
end
for i=valid_handles
    for j=1:3
        set(st.vols{i}.ax{j}.lx,'Visible',opt);
        set(st.vols{i}.ax{j}.ly,'Visible',opt);
    end
end
function cm_pos
    global st
    for i = 1:numel(valid_handles)
        if isfield(st.vols{i}.ax{1},'cm')
            set(findobj(st.vols{i}.ax{1}.cm,'UserData','pos_mm'),...
                'Label',sprintf('mm:  %.1f %.1f %.1f',bspm_orthviews('pos')));
            pos = bspm_orthviews('pos',i);
            set(findobj(st.vols{i}.ax{1}.cm,'UserData','pos_vx'),...
                'Label',sprintf('vx:  %.1f %.1f %.1f',pos));
            try
                Y = spm_sample_vol(st.vols{i},pos(1),pos(2),pos(3),st.hld);
            catch
                Y = NaN;
                fprintf('Cannot access file "%s".\n', st.vols{i}.fname);
            end
            set(findobj(st.vols{i}.ax{1}.cm,'UserData','v_value'),...
                'Label',sprintf('Y = %g',Y));
        end
    end
function my_reset
    global st
    % if ~isempty(st) && isfield(st,'registry') && ishandle(st.registry.hMe)
    %     delete(st.registry.hMe); st = rmfield(st,'registry');
    % end
    my_delete(1:max_img);
    reset_st;
function my_delete(handle)
global st
% remove blobs (and colourbars, if any)
rmblobs(handle);
% remove displayed axes
for i=valid_handles(handle)
    kids = get(st.fig,'Children');
    for j=1:3
        try
            if any(kids == st.vols{i}.ax{j}.ax)
                set(get(st.vols{i}.ax{j}.ax,'Children'),'DeleteFcn','');
                delete(st.vols{i}.ax{j}.ax);
            end
        end
    end
    st.vols{i} = [];
end
function resolution(res)
global st
if ~nargin, res = 1; end % Default minimum resolution 1mm
for i=valid_handles
    % adapt resolution to smallest voxel size of displayed images
    res  = min([res,sqrt(sum((st.vols{i}.mat(1:3,1:3)).^2))]);
end
res      = res/mean(svd(st.Space(1:3,1:3)));
Mat      = diag([res res res 1]);
st.Space = st.Space*Mat;
st.bb    = st.bb/res;
function move(handle,pos)
global st
for i=valid_handles(handle)
    st.vols{i}.area = pos;
end
bbox;
function space(handle,M,dim)
global st
if ~isempty(st.vols{handle})
    if nargin < 2
        M = st.vols{handle}.mat;
        dim = st.vols{handle}.dim(1:3);
    end
    Mat   = st.vols{handle}.premul(1:3,1:3)*M(1:3,1:3);
    vox   = sqrt(sum(Mat.^2));
    if det(Mat(1:3,1:3))<0, vox(1) = -vox(1); end
    Mat   = diag([vox 1]);
    Space = (M)/Mat;
    bb    = [1 1 1; dim];
    bb    = [bb [1;1]];
    bb    = bb*Mat';
    bb    = bb(:,1:3);
    bb    = sort(bb);
    st.Space = Space;
    st.bb = bb;
end
function zoom_op(fov,res)
global st
if nargin < 1, fov = Inf; end
if nargin < 2, res = Inf; end

if isinf(fov)
    st.bb = maxbb;
elseif isnan(fov) || fov == 0
    current_handle = valid_handles;
    if numel(current_handle) > 1 % called from check reg context menu
        current_handle = get_current_handle;
    end
    if fov == 0
        % zoom to bounding box of current image ~= 0
        thr = 'nz';
    else
        % zoom to bounding box of current image > chosen threshold
        thr = spm_input('Threshold (Y > ...)', '+1', 'r', '0', 1);
    end
    premul = st.Space \ st.vols{current_handle}.premul;
    st.bb = spm_get_bbox(st.vols{current_handle}, thr, premul);
else
    vx    = sqrt(sum(st.Space(1:3,1:3).^2));
    vx    = vx.^(-1);
    pos   = bspm_orthviews('pos');
    pos   = st.Space\[pos ; 1];
    pos   = pos(1:3)';
    st.bb = [pos-fov*vx; pos+fov*vx];
end
resolution(res);
bbox;
redraw_all;
if isfield(st.vols{1},'sdip')
    spm_eeg_inv_vbecd_disp('RedrawDip');
end
function bbox
global st
Dims = diff(st.bb)'+1;

TD = Dims([1 2])';
CD = Dims([1 3])';
if st.mode == 0, SD = Dims([3 2])'; else SD = Dims([2 3])'; end

un    = get(st.fig,'Units');set(st.fig,'Units','Pixels');
sz    = get(st.fig,'Position');set(st.fig,'Units',un);
sz    = sz(3:4);
sz(2) = sz(2)-40;

for i=valid_handles
    area   = st.vols{i}.area(:);
    area   = [area(1)*sz(1) area(2)*sz(2) area(3)*sz(1) area(4)*sz(2)];
    if st.mode == 0
        sx = area(3)/(Dims(1)+Dims(3))/1.02;
    else
        sx = area(3)/(Dims(1)+Dims(2))/1.02;
    end
    sy     = area(4)/(Dims(2)+Dims(3))/1.02;
    s      = min([sx sy]);
    
    offy   = (area(4)-(Dims(2)+Dims(3))*1.02*s)/2 + area(2);
    sky    = s*(Dims(2)+Dims(3))*0.02;
    if st.mode == 0
        offx = (area(3)-(Dims(1)+Dims(3))*1.02*s)/2 + area(1);
        skx  = s*(Dims(1)+Dims(3))*0.02;
    else
        offx = (area(3)-(Dims(1)+Dims(2))*1.02*s)/2 + area(1);
        skx  = s*(Dims(1)+Dims(2))*0.02;
    end
    
    % Transverse
    set(st.vols{i}.ax{1}.ax,'Units','pixels', ...
        'Position',[offx offy s*Dims(1) s*Dims(2)],...
        'Units','normalized','Xlim',[0 TD(1)]+0.5,'Ylim',[0 TD(2)]+0.5,...
        'Visible','on','XTick',[],'YTick',[]);
    
    % Coronal
    set(st.vols{i}.ax{2}.ax,'Units','Pixels',...
        'Position',[offx offy+s*Dims(2)+sky s*Dims(1) s*Dims(3)],...
        'Units','normalized','Xlim',[0 CD(1)]+0.5,'Ylim',[0 CD(2)]+0.5,...
        'Visible','on','XTick',[],'YTick',[]);
    
    % Sagittal
    if st.mode == 0
        set(st.vols{i}.ax{3}.ax,'Units','Pixels', 'Box','on',...
            'Position',[offx+s*Dims(1)+skx offy s*Dims(3) s*Dims(2)],...
            'Units','normalized','Xlim',[0 SD(1)]+0.5,'Ylim',[0 SD(2)]+0.5,...
            'Visible','on','XTick',[],'YTick',[]);
    else
        set(st.vols{i}.ax{3}.ax,'Units','Pixels', 'Box','on',...
            'Position',[offx+s*Dims(1)+skx offy+s*Dims(2)+sky s*Dims(2) s*Dims(3)],...
            'Units','normalized','Xlim',[0 SD(1)]+0.5,'Ylim',[0 SD(2)]+0.5,...
            'Visible','on','XTick',[],'YTick',[]);
    end
end
function redraw(arg1)
    global st
    bb   = st.bb;
    Dims = round(diff(bb)'+1);
    is   = inv(st.Space);
    cent = is(1:3,1:3)*st.centre(:) + is(1:3,4);
    for i = valid_handles(arg1)
        M = st.Space\st.vols{i}.premul*st.vols{i}.mat;
        TM0 = [ 1 0 0 -bb(1,1)+1
                0 1 0 -bb(1,2)+1
                0 0 1 -cent(3)
                0 0 0 1];
        TM = inv(TM0*M);
        TD = Dims([1 2]);

        CM0 = [ 1 0 0 -bb(1,1)+1
                0 0 1 -bb(1,3)+1
                0 1 0 -cent(2)
                0 0 0 1];
        CM = inv(CM0*M);
        CD = Dims([1 3]);
        if st.mode ==0
            SM0 = [ 0 0 1 -bb(1,3)+1
                    0 1 0 -bb(1,2)+1
                    1 0 0 -cent(1)
                    0 0 0 1];
            SM = inv(SM0*M); 
            SD = Dims([3 2]);
        else
            SM0 = [ 0 -1 0 +bb(2,2)+1
                    0  0 1 -bb(1,3)+1
                    1  0 0 -cent(1)
                    0  0 0 1];
            SM = inv(SM0*M);
            SD = Dims([2 3]);
        end
        try
            imgt = spm_slice_vol(st.vols{i},TM,TD,st.hld)';
            imgc = spm_slice_vol(st.vols{i},CM,CD,st.hld)';
            imgs = spm_slice_vol(st.vols{i},SM,SD,st.hld)';
            imgc2 = adjustbrightness(imgc); 
            imgs2 = adjustbrightness(imgs); 
            imgt2 = adjustbrightness(imgt); 
            ok   = true;
        catch
            fprintf('Cannot access file "%s".\n', st.vols{i}.fname);
            fprintf('%s\n',getfield(lasterror,'message'));
            ok   = false;
        end
        if ok
            % get min/max threshold
            if strcmp(st.vols{i}.window,'auto')
                mn = -Inf;
                mx = Inf;
            else
                mn = min(st.vols{i}.window);
                mx = max(st.vols{i}.window);
            end
            % threshold images
            imgt = max(imgt,mn); imgt = min(imgt,mx);
            imgc = max(imgc,mn); imgc = min(imgc,mx);
            imgs = max(imgs,mn); imgs = min(imgs,mx);
            % compute intensity mapping, if histeq is available
            if license('test','image_toolbox') == 0
                st.vols{i}.mapping = 'linear';
            end
            switch st.vols{i}.mapping
                case 'linear'
                case 'histeq'
                    % scale images to a range between 0 and 1
                    imgt1=(imgt-min(imgt(:)))/(max(imgt(:)-min(imgt(:)))+eps);
                    imgc1=(imgc-min(imgc(:)))/(max(imgc(:)-min(imgc(:)))+eps);
                    imgs1=(imgs-min(imgs(:)))/(max(imgs(:)-min(imgs(:)))+eps);
                    img  = histeq([imgt1(:); imgc1(:); imgs1(:)],1024);
                    imgt = reshape(img(1:numel(imgt1)),size(imgt1));
                    imgc = reshape(img(numel(imgt1)+(1:numel(imgc1))),size(imgc1));
                    imgs = reshape(img(numel(imgt1)+numel(imgc1)+(1:numel(imgs1))),size(imgs1));
                    mn = 0;
                    mx = 1;
                case 'quadhisteq'
                    % scale images to a range between 0 and 1
                    imgt1=(imgt-min(imgt(:)))/(max(imgt(:)-min(imgt(:)))+eps);
                    imgc1=(imgc-min(imgc(:)))/(max(imgc(:)-min(imgc(:)))+eps);
                    imgs1=(imgs-min(imgs(:)))/(max(imgs(:)-min(imgs(:)))+eps);
                    img  = histeq([imgt1(:).^2; imgc1(:).^2; imgs1(:).^2],1024);
                    imgt = reshape(img(1:numel(imgt1)),size(imgt1));
                    imgc = reshape(img(numel(imgt1)+(1:numel(imgc1))),size(imgc1));
                    imgs = reshape(img(numel(imgt1)+numel(imgc1)+(1:numel(imgs1))),size(imgs1));
                    mn = 0;
                    mx = 1;
                case 'loghisteq'
                    sw = warning('off','MATLAB:log:logOfZero');
                    imgt = log(imgt-min(imgt(:)));
                    imgc = log(imgc-min(imgc(:)));
                    imgs = log(imgs-min(imgs(:)));
                    warning(sw);
                    imgt(~isfinite(imgt)) = 0;
                    imgc(~isfinite(imgc)) = 0;
                    imgs(~isfinite(imgs)) = 0;
                    % scale log images to a range between 0 and 1
                    imgt1=(imgt-min(imgt(:)))/(max(imgt(:)-min(imgt(:)))+eps);
                    imgc1=(imgc-min(imgc(:)))/(max(imgc(:)-min(imgc(:)))+eps);
                    imgs1=(imgs-min(imgs(:)))/(max(imgs(:)-min(imgs(:)))+eps);
                    img  = histeq([imgt1(:); imgc1(:); imgs1(:)],1024);
                    imgt = reshape(img(1:numel(imgt1)),size(imgt1));
                    imgc = reshape(img(numel(imgt1)+(1:numel(imgc1))),size(imgc1));
                    imgs = reshape(img(numel(imgt1)+numel(imgc1)+(1:numel(imgs1))),size(imgs1));
                    mn = 0;
                    mx = 1;
            end
            % recompute min/max for display
            if strcmp(st.vols{i}.window,'auto')
                mx = -inf; mn = inf;
            end
            if ~isempty(imgt)
                tmp = imgt(isfinite(imgt));
                mx = max([mx max(max(tmp))]);
                mn = min([mn min(min(tmp))]);
            end
            if ~isempty(imgc)
                tmp = imgc(isfinite(imgc));
                mx = max([mx max(max(tmp))]);
                mn = min([mn min(min(tmp))]);
            end
            if ~isempty(imgs)
                tmp = imgs(isfinite(imgs));
                mx = max([mx max(max(tmp))]);
                mn = min([mn min(min(tmp))]);
            end
            if mx==mn, mx=mn+eps; end
            if isfield(st.vols{i},'blobs')
                if ~isfield(st.vols{i}.blobs{1},'colour')
                    % Add blobs for display using the split colourmap
                    scal = 64/(mx-mn);
                    dcoff = -mn*scal;
                    imgt = imgt*scal+dcoff;
                    imgc = imgc*scal+dcoff;
                    imgs = imgs*scal+dcoff;

                    if isfield(st.vols{i}.blobs{1},'max')
                        mx = st.vols{i}.blobs{1}.max;
                    else
                        mx = max([eps maxval(st.vols{i}.blobs{1}.vol)]);
                        st.vols{i}.blobs{1}.max = mx;
                    end
                    if isfield(st.vols{i}.blobs{1},'min')
                        mn = st.vols{i}.blobs{1}.min;
                    else
                        mn = min([0 minval(st.vols{i}.blobs{1}.vol)]);
                        st.vols{i}.blobs{1}.min = mn;
                    end

                    vol  = st.vols{i}.blobs{1}.vol;
                    M    = st.Space\st.vols{i}.premul*st.vols{i}.blobs{1}.mat;
                    tmpt = spm_slice_vol(vol,inv(TM0*M),TD,[0 NaN])';
                    tmpc = spm_slice_vol(vol,inv(CM0*M),CD,[0 NaN])';
                    tmps = spm_slice_vol(vol,inv(SM0*M),SD,[0 NaN])';

                    %tmpt_z = find(tmpt==0);tmpt(tmpt_z) = NaN;
                    %tmpc_z = find(tmpc==0);tmpc(tmpc_z) = NaN;
                    %tmps_z = find(tmps==0);tmps(tmps_z) = NaN;

                    sc   = 64/(mx-mn);
                    off  = 65.51-mn*sc;
                    msk  = find(isfinite(tmpt)); imgt(msk) = off+tmpt(msk)*sc;
                    msk  = find(isfinite(tmpc)); imgc(msk) = off+tmpc(msk)*sc;
                    msk  = find(isfinite(tmps)); imgs(msk) = off+tmps(msk)*sc;


                    cmap = get(st.fig,'Colormap');
                    if size(cmap,1)~=128
                        setcolormap(jet(64));
    %                     spm_figure('Colormap','gray-hot')
                    end
                    figure(st.fig)
                    redraw_colourbar(i,1,[mn mx],(1:64)'+64);
                elseif isstruct(st.vols{i}.blobs{1}.colour)
                    % Add blobs for display using a defined colourmap

                    % colourmaps
                    gryc = (0:63)'*ones(1,3)/63;

                    % scale grayscale image, not isfinite -> black
                    gimgt = scaletocmap(imgt,mn,mx,gryc,65);
                    gimgc = scaletocmap(imgc,mn,mx,gryc,65);
                    gimgs = scaletocmap(imgs,mn,mx,gryc,65);
                    gryc  = [gryc; 0 0 0];
                    cactp = 0;

                    for j=1:numel(st.vols{i}.blobs)
                        % colourmaps
                        actc = st.vols{i}.blobs{j}.colour.cmap;
                        actp = st.vols{i}.blobs{j}.colour.prop;

                        % get min/max for blob image
                        if isfield(st.vols{i}.blobs{j},'max')
                            cmx = st.vols{i}.blobs{j}.max;
                        else
                            cmx = max([eps maxval(st.vols{i}.blobs{j}.vol)]);
                        end
                        if isfield(st.vols{i}.blobs{j},'min')
                            cmn = st.vols{i}.blobs{j}.min;
                        else
                            cmn = -cmx;
                        end

                        % get blob data
                        vol  = st.vols{i}.blobs{j}.vol;
                        M    = st.Space\st.vols{i}.premul*st.vols{i}.blobs{j}.mat;
                        tmpt = spm_slice_vol(vol,inv(TM0*M),TD,[0 NaN])';
                        tmpc = spm_slice_vol(vol,inv(CM0*M),CD,[0 NaN])';
                        tmps = spm_slice_vol(vol,inv(SM0*M),SD,[0 NaN])';

                        % actimg scaled round 0, black NaNs
                        topc = size(actc,1)+1;
                        tmpt = scaletocmap(tmpt,cmn,cmx,actc,topc);
                        tmpc = scaletocmap(tmpc,cmn,cmx,actc,topc);
                        tmps = scaletocmap(tmps,cmn,cmx,actc,topc);
                        actc = [actc; 0 0 0];

                        % combine gray and blob data to truecolour
                        if isnan(actp)
                            if j==1, imgt = gryc(gimgt(:),:); end
                            imgt(tmpt~=size(actc,1),:) = actc(tmpt(tmpt~=size(actc,1)),:);
                            if j==1, imgc = gryc(gimgc(:),:); end
                            imgc(tmpc~=size(actc,1),:) = actc(tmpc(tmpc~=size(actc,1)),:);
                            if j==1, imgs = gryc(gimgs(:),:); end
                            imgs(tmps~=size(actc,1),:) = actc(tmps(tmps~=size(actc,1)),:);
                        else
                            cactp = cactp + actp;
                            if j==1, imgt = actc(tmpt(:),:)*actp; else imgt = imgt + actc(tmpt(:),:)*actp; end
                            if j==numel(st.vols{i}.blobs), imgt = imgt + gryc(gimgt(:),:)*(1-cactp); end
                            if j==1, imgc = actc(tmpc(:),:)*actp; else imgc = imgc + actc(tmpc(:),:)*actp; end
                            if j==numel(st.vols{i}.blobs), imgc = imgc + gryc(gimgc(:),:)*(1-cactp); end
                            if j==1, imgs = actc(tmps(:),:)*actp; else imgs = imgs + actc(tmps(:),:)*actp; end
                            if j==numel(st.vols{i}.blobs), imgs = imgs + gryc(gimgs(:),:)*(1-cactp); end
                        end
                        if j==numel(st.vols{i}.blobs)
                            imgt = reshape(imgt,[size(gimgt) 3]);
                            imgc = reshape(imgc,[size(gimgc) 3]);
                            imgs = reshape(imgs,[size(gimgs) 3]);
                        end

                         % colourbar
                        csz   = size(st.vols{i}.blobs{j}.colour.cmap);
                        cdata = reshape(st.vols{i}.blobs{j}.colour.cmap, [csz(1) 1 csz(2)]);
                        redraw_colourbar(i,j,[cmn cmx],cdata);
                    end

                else
                    % Add full colour blobs - several sets at once
                    scal  = 1/(mx-mn);
                    dcoff = -mn*scal;

                    wt = zeros(size(imgt));
                    wc = zeros(size(imgc));
                    ws = zeros(size(imgs));

                    imgt  = repmat(imgt*scal+dcoff,[1,1,3]);
                    imgc  = repmat(imgc*scal+dcoff,[1,1,3]);
                    imgs  = repmat(imgs*scal+dcoff,[1,1,3]);

                    cimgt = zeros(size(imgt));
                    cimgc = zeros(size(imgc));
                    cimgs = zeros(size(imgs));

                    colour = zeros(numel(st.vols{i}.blobs),3);
                    for j=1:numel(st.vols{i}.blobs) % get colours of all images first
                        if isfield(st.vols{i}.blobs{j},'colour')
                            colour(j,:) = reshape(st.vols{i}.blobs{j}.colour, [1 3]);
                        else
                            colour(j,:) = [1 0 0];
                        end
                    end
                    %colour = colour/max(sum(colour));

                    for j=1:numel(st.vols{i}.blobs)
                        if isfield(st.vols{i}.blobs{j},'max')
                            mx = st.vols{i}.blobs{j}.max;
                        else
                            mx = max([eps max(st.vols{i}.blobs{j}.vol(:))]);
                            st.vols{i}.blobs{j}.max = mx;
                        end
                        if isfield(st.vols{i}.blobs{j},'min')
                            mn = st.vols{i}.blobs{j}.min;
                        else
                            mn = min([0 min(st.vols{i}.blobs{j}.vol(:))]);
                            st.vols{i}.blobs{j}.min = mn;
                        end

                        vol  = st.vols{i}.blobs{j}.vol;
                        M    = st.Space\st.vols{i}.premul*st.vols{i}.blobs{j}.mat;
                        tmpt = spm_slice_vol(vol,inv(TM0*M),TD,[0 NaN])';
                        tmpc = spm_slice_vol(vol,inv(CM0*M),CD,[0 NaN])';
                        tmps = spm_slice_vol(vol,inv(SM0*M),SD,[0 NaN])';
                        % check min/max of sampled image
                        % against mn/mx as given in st
                        tmpt(tmpt(:)<mn) = mn;
                        tmpc(tmpc(:)<mn) = mn;
                        tmps(tmps(:)<mn) = mn;
                        tmpt(tmpt(:)>mx) = mx;
                        tmpc(tmpc(:)>mx) = mx;
                        tmps(tmps(:)>mx) = mx;
                        tmpt = (tmpt-mn)/(mx-mn);
                        tmpc = (tmpc-mn)/(mx-mn);
                        tmps = (tmps-mn)/(mx-mn);
                        tmpt(~isfinite(tmpt)) = 0;
                        tmpc(~isfinite(tmpc)) = 0;
                        tmps(~isfinite(tmps)) = 0;

                        cimgt = cimgt + cat(3,tmpt*colour(j,1),tmpt*colour(j,2),tmpt*colour(j,3));
                        cimgc = cimgc + cat(3,tmpc*colour(j,1),tmpc*colour(j,2),tmpc*colour(j,3));
                        cimgs = cimgs + cat(3,tmps*colour(j,1),tmps*colour(j,2),tmps*colour(j,3));

                        wt = wt + tmpt;
                        wc = wc + tmpc;
                        ws = ws + tmps;
                        cdata=permute(shiftdim((1/64:1/64:1)'* ...
                            colour(j,:),-1),[2 1 3]);
                        redraw_colourbar(i,j,[mn mx],cdata);
                    end

                    imgt = repmat(1-wt,[1 1 3]).*imgt+cimgt;
                    imgc = repmat(1-wc,[1 1 3]).*imgc+cimgc;
                    imgs = repmat(1-ws,[1 1 3]).*imgs+cimgs;

                    imgt(imgt<0)=0; imgt(imgt>1)=1;
                    imgc(imgc<0)=0; imgc(imgc>1)=1;
                    imgs(imgs<0)=0; imgs(imgs>1)=1;
                end
            else
                scal = 64/(mx-mn);
                dcoff = -mn*scal;
                imgt = imgt*scal+dcoff;
                imgc = imgc*scal+dcoff;
                imgs = imgs*scal+dcoff;
            end
            set(st.vols{i}.ax{1}.d,'HitTest','off', 'Cdata',imgt);
            set(st.vols{i}.ax{1}.lx,'HitTest','off',...
                'Xdata',[0 TD(1)]+0.5,'Ydata',[1 1]*(cent(2)-bb(1,2)+1));
            set(st.vols{i}.ax{1}.ly,'HitTest','off',...
                'Ydata',[0 TD(2)]+0.5,'Xdata',[1 1]*(cent(1)-bb(1,1)+1));
            set(st.vols{i}.ax{2}.d,'HitTest','off', 'Cdata',imgc);
            set(st.vols{i}.ax{2}.lx,'HitTest','off',...
                'Xdata',[0 CD(1)]+0.5,'Ydata',[1 1]*(cent(3)-bb(1,3)+1));
            set(st.vols{i}.ax{2}.ly,'HitTest','off',...
                'Ydata',[0 CD(2)]+0.5,'Xdata',[1 1]*(cent(1)-bb(1,1)+1));
            set(st.vols{i}.ax{3}.d,'HitTest','off','Cdata',imgs);
            if st.mode ==0
                set(st.vols{i}.ax{3}.lx,'HitTest','off',...
                    'Xdata',[0 SD(1)]+0.5,'Ydata',[1 1]*(cent(2)-bb(1,2)+1));
                set(st.vols{i}.ax{3}.ly,'HitTest','off',...
                    'Ydata',[0 SD(2)]+0.5,'Xdata',[1 1]*(cent(3)-bb(1,3)+1));
            else
                set(st.vols{i}.ax{3}.lx,'HitTest','off',...
                    'Xdata',[0 SD(1)]+0.5,'Ydata',[1 1]*(cent(3)-bb(1,3)+1));
                set(st.vols{i}.ax{3}.ly,'HitTest','off',...
                    'Ydata',[0 SD(2)]+0.5,'Xdata',[1 1]*(bb(2,2)+1-cent(2)));
            end
            if ~isempty(st.plugins) % process any addons
                for k = 1:numel(st.plugins)
                    if isfield(st.vols{i},st.plugins{k})
                        feval(['spm_ov_', st.plugins{k}], ...
                            'redraw', i, TM0, TD, CM0, CD, SM0, SD);
                    end
                end
            end
        end
    end
    drawnow;
function redraw_all
redraw(1:max_img);
function reset_st
global st
fig = spm_figure('FindWin','Graphics');
bb  = []; %[ [-78 78]' [-112 76]' [-50 85]' ];
st  = struct('n', 0, 'vols',{cell(max_img,1)}, 'bb',bb, 'Space',eye(4), ...
             'centre',[0 0 0], 'callback',';', 'xhairs',1, 'hld',1, ...
             'fig',fig, 'mode',1, 'plugins',{{}}, 'snap',[]);
xTB = spm('TBs');
if ~isempty(xTB)
    pluginbase = {spm('Dir') xTB.dir};
else
    pluginbase = {spm('Dir')};
end
for k = 1:numel(pluginbase)
    pluginpath = fullfile(pluginbase{k},'spm_orthviews');
    pluginpath = fileparts(mfilename); 
    if isdir(pluginpath)
        pluginfiles = dir(fullfile(pluginpath,'spm_ov_*.m'));
        if ~isempty(pluginfiles)
            if ~isdeployed, addpath(pluginpath); end
            for l = 1:numel(pluginfiles)
                pluginname = spm_file(pluginfiles(l).name,'basename');
                st.plugins{end+1} = strrep(pluginname, 'spm_ov_','');
            end
        end
    end
end
function c_menu(varargin)
global st

switch lower(varargin{1})
    case 'image_info'
        if nargin <3
            current_handle = get_current_handle;
        else
            current_handle = varargin{3};
        end
        if isfield(st.vols{current_handle},'fname')
            [p,n,e,v] = spm_fileparts(st.vols{current_handle}.fname);
            if isfield(st.vols{current_handle},'n')
                v = sprintf(',%d',st.vols{current_handle}.n);
            end
            set(varargin{2}, 'Label',[n e v]);
        end
        delete(get(varargin{2},'children'));
        if exist('p','var')
            item1 = uimenu(varargin{2}, 'Label', p);
        end
        if isfield(st.vols{current_handle},'descrip')
            item2 = uimenu(varargin{2}, 'Label',...
                st.vols{current_handle}.descrip);
        end
        dt = st.vols{current_handle}.dt(1);
        item3 = uimenu(varargin{2}, 'Label', sprintf('Data type: %s', spm_type(dt)));
        str   = 'Intensity: varied';
        if size(st.vols{current_handle}.pinfo,2) == 1
            if st.vols{current_handle}.pinfo(2)
                str = sprintf('Intensity: Y = %g X + %g',...
                    st.vols{current_handle}.pinfo(1:2)');
            else
                str = sprintf('Intensity: Y = %g X', st.vols{current_handle}.pinfo(1)');
            end
        end
        item4  = uimenu(varargin{2}, 'Label',str);
        item5  = uimenu(varargin{2}, 'Label', 'Image dimensions', 'Separator','on');
        item51 = uimenu(varargin{2}, 'Label',...
            sprintf('%dx%dx%d', st.vols{current_handle}.dim(1:3)));
        
        prms   = spm_imatrix(st.vols{current_handle}.mat);
        item6  = uimenu(varargin{2}, 'Label', 'Voxel size', 'Separator','on');
        item61 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', prms(7:9)));
        
        O      = st.vols{current_handle}.mat\[0 0 0 1]'; O=O(1:3)';
        item7  = uimenu(varargin{2}, 'Label', 'Origin', 'Separator','on');
        item71 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', O));
        
        R      = spm_matrix([0 0 0 prms(4:6)]);
        item8  = uimenu(varargin{2}, 'Label', 'Rotations', 'Separator','on');
        item81 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', R(1,1:3)));
        item82 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', R(2,1:3)));
        item83 = uimenu(varargin{2}, 'Label', sprintf('%.2f %.2f %.2f', R(3,1:3)));
        item9  = uimenu(varargin{2},...
            'Label','Specify other image...',...
            'Callback','bspm_orthviews(''context_menu'',''swap_img'');',...
            'Separator','on');
        
    case 'repos_mm'
        oldpos_mm = bspm_orthviews('pos');
        newpos_mm = spm_input('New Position (mm)','+1','r',sprintf('%.2f %.2f %.2f',oldpos_mm),3);
        bspm_orthviews('reposition',newpos_mm);
        
    case 'repos_vx'
        current_handle = get_current_handle;
        oldpos_vx = bspm_orthviews('pos', current_handle);
        newpos_vx = spm_input('New Position (voxels)','+1','r',sprintf('%.2f %.2f %.2f',oldpos_vx),3);
        newpos_mm = st.vols{current_handle}.mat*[newpos_vx;1];
        bspm_orthviews('reposition',newpos_mm(1:3));
        
    case 'zoom'
        zoom_all(varargin{2:end});
        bbox;
        redraw_all;
        
    case 'xhair'
        bspm_orthviews('Xhairs',varargin{2:end});
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = findobj(cm_handles(i),'label','Crosshairs');
            if st.xhairs
                set(z_handle,'Checked','on');
            else
                set(z_handle,'Checked','off');
            end
        end
        
    case 'orientation'
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Orientation'),'Children');
            set(z_handle,'Checked','off');
        end
        if varargin{2} == 3
            bspm_orthviews('Space');
            for i = 1:numel(cm_handles),
                z_handle = findobj(cm_handles(i),'label','World space');
                set(z_handle,'Checked','on');
            end
        elseif varargin{2} == 2,
            bspm_orthviews('Space',1);
            for i = 1:numel(cm_handles)
                z_handle = findobj(cm_handles(i),'label',...
                    'Voxel space (1st image)');
                set(z_handle,'Checked','on');
            end
        else
            bspm_orthviews('Space',get_current_handle);
            z_handle = findobj(st.vols{get_current_handle}.ax{1}.cm, ...
                'label','Voxel space (this image)');
            set(z_handle,'Checked','on');
            return;
        end
        
    case 'snap'
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Snap to Grid'),'Children');
            set(z_handle,'Checked','off');
        end
        if varargin{2} == 3
            st.snap = [];
        elseif varargin{2} == 2
            st.snap = 1;
        else
            st.snap = get_current_handle;
            z_handle = get(findobj(st.vols{get_current_handle}.ax{1}.cm,'label','Snap to Grid'),'Children');
            set(z_handle(1),'Checked','on');
            return;
        end
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Snap to Grid'),'Children');
            set(z_handle(varargin{2}),'Checked','on');
        end
        
    case 'interpolation'
        tmp        = [-4 1 0];
        st.hld     = tmp(varargin{2});
        cm_handles = get_cm_handles;
        for i = 1:numel(cm_handles)
            z_handle = get(findobj(cm_handles(i),'label','Interpolation'),'Children');
            set(z_handle,'Checked','off');
            set(z_handle(varargin{2}),'Checked','on');
        end
        redraw_all;
        
    case 'window'
        current_handle = get_current_handle;
        if varargin{2} == 2
            bspm_orthviews('window',current_handle);
        elseif varargin{2} == 3
            pc = spm_input('Percentiles', '+1', 'w', '3 97', 2, 100);
            wn = spm_summarise(st.vols{current_handle}, 'all', ...
                @(X) spm_percentile(X, pc));
            bspm_orthviews('window',current_handle,wn);
        else
            if isnumeric(st.vols{current_handle}.window)
                defstr = sprintf('%.2f %.2f', st.vols{current_handle}.window);
            else
                defstr = '';
            end
            [w,yp] = spm_input('Range','+1','e',defstr,[1 inf]);
            while numel(w) < 1 || numel(w) > 2
                uiwait(warndlg('Window must be one or two numbers','Wrong input size','modal'));
                [w,yp] = spm_input('Range',yp,'e',defstr,[1 inf]);
            end
            if numel(w) == 1
                w(2) = w(1)+eps;
            end
            bspm_orthviews('window',current_handle,w);
        end
        
    case 'window_gl'
        if varargin{2} == 2
            for i = 1:numel(get_cm_handles)
                st.vols{i}.window = 'auto';
            end
        else
            current_handle = get_current_handle;
            if isnumeric(st.vols{current_handle}.window)
                defstr = sprintf('%d %d', st.vols{current_handle}.window);
            else
                defstr = '';
            end
            [w,yp] = spm_input('Range','+1','e',defstr,[1 inf]);
            while numel(w) < 1 || numel(w) > 2
                uiwait(warndlg('Window must be one or two numbers','Wrong input size','modal'));
                [w,yp] = spm_input('Range',yp,'e',defstr,[1 inf]);
            end
            if numel(w) == 1
                w(2) = w(1)+eps;
            end
            for i = 1:numel(get_cm_handles)
                st.vols{i}.window = w;
            end
        end
        redraw_all;
        
    case 'mapping'
        checked = strcmp(varargin{2}, ...
            {'linear', 'histeq', 'loghisteq', 'quadhisteq'});
        checked = checked(end:-1:1); % Handles are stored in inverse order
        current_handle = get_current_handle;
        cm_handles = get_cm_handles;
        st.vols{current_handle}.mapping = varargin{2};
        z_handle = get(findobj(cm_handles(current_handle), ...
            'label','Intensity mapping'),'Children');
        for k = 1:numel(z_handle)
            c_handle = get(z_handle(k), 'Children');
            set(c_handle, 'checked', 'off');
            set(c_handle(checked), 'checked', 'on');
        end
        redraw_all;
        
    case 'mapping_gl'
        checked = strcmp(varargin{2}, ...
            {'linear', 'histeq', 'loghisteq', 'quadhisteq'});
        checked = checked(end:-1:1); % Handles are stored in inverse order
        cm_handles = get_cm_handles;
        for k = valid_handles
            st.vols{k}.mapping = varargin{2};
            z_handle = get(findobj(cm_handles(k), ...
                'label','Intensity mapping'),'Children');
            for l = 1:numel(z_handle)
                c_handle = get(z_handle(l), 'Children');
                set(c_handle, 'checked', 'off');
                set(c_handle(checked), 'checked', 'on');
            end
        end
        redraw_all;
        
    case 'swap_img'
        current_handle = get_current_handle;
        newimg = spm_select(1,'image','select new image');
        if ~isempty(newimg)
            new_info = spm_vol(newimg);
            fn = fieldnames(new_info);
            for k=1:numel(fn)
                st.vols{current_handle}.(fn{k}) = new_info.(fn{k});
            end
            bspm_orthviews('context_menu','image_info',get(gcbo, 'parent'));
            redraw_all;
        end
        
    case 'add_blobs'
        % Add blobs to the image - in split colortable
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        [SPM,xSPM] = spm_getSPM;
        if ~isempty(SPM)
            for i = 1:numel(cm_handles)
                addblobs(cm_handles(i),xSPM.XYZ,xSPM.Z,xSPM.M);
                % Add options for removing blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove blobs');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                item7_3_1 = uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',2);');
                if varargin{2} == 1,
                    item7_3_2 = uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',1);');
                end
                % Add options for setting maxima for blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Set blobs max');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',2);');
                if varargin{2} == 1
                    uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',1);');
                end
            end
            redraw_all;
        end
        
    case 'remove_blobs'
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        for i = 1:numel(cm_handles)
            rmblobs(cm_handles(i));
            % Remove options for removing blobs
            c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove blobs');
            delete(get(c_handle,'Children'));
            set(c_handle,'Visible','off');
            % Remove options for setting maxima for blobs
            c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Set blobs max');
            set(c_handle,'Visible','off');
        end
        redraw_all;
        
    case 'add_image'
        % Add blobs to the image - in split colortable
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        fname = spm_select(1,'image','select image');
        if ~isempty(fname)
            for i = 1:numel(cm_handles)
                addimage(cm_handles(i),fname);
                % Add options for removing blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove blobs');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                item7_3_1 = uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',2);');
                if varargin{2} == 1
                    item7_3_2 = uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''remove_blobs'',1);');
                end
                % Add options for setting maxima for blobs
                c_handle = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Set blobs max');
                set(c_handle,'Visible','on');
                delete(get(c_handle,'Children'));
                uimenu(c_handle,'Label','local','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',2);');
                if varargin{2} == 1
                    uimenu(c_handle,'Label','global','Callback','bspm_orthviews(''context_menu'',''setblobsmax'',1);');
                end
            end
            redraw_all;
        end
        
    case 'add_c_blobs'
        % Add blobs to the image - in full colour
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        [SPM,xSPM] = spm_getSPM;
        if ~isempty(SPM)
            c = spm_input('Colour','+1','m',...
                'Red blobs|Yellow blobs|Green blobs|Cyan blobs|Blue blobs|Magenta blobs',[1 2 3 4 5 6],1);
            colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
            c_names = {'red';'yellow';'green';'cyan';'blue';'magenta'};
            hlabel = sprintf('%s (%s)',xSPM.title,c_names{c});
            for i = 1:numel(cm_handles)
                addcolouredblobs(cm_handles(i),xSPM.XYZ,xSPM.Z,xSPM.M,colours(c,:),xSPM.title);
                addcolourbar(cm_handles(i),numel(st.vols{cm_handles(i)}.blobs));
                c_handle    = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove coloured blobs');
                ch_c_handle = get(c_handle,'Children');
                set(c_handle,'Visible','on');
                %set(ch_c_handle,'Visible',on');
                item7_4_1   = uimenu(ch_c_handle(2),'Label',hlabel,'ForegroundColor',colours(c,:),...
                    'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',2,c);',...
                    'UserData',c);
                if varargin{2} == 1
                    item7_4_2 = uimenu(ch_c_handle(1),'Label',hlabel,'ForegroundColor',colours(c,:),...
                        'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',1,c);',...
                        'UserData',c);
                end
            end
            redraw_all;
        end
        
    case 'remove_c_blobs'
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
        for i = 1:numel(cm_handles)
            if isfield(st.vols{cm_handles(i)},'blobs')
                for j = 1:numel(st.vols{cm_handles(i)}.blobs)
                    if all(st.vols{cm_handles(i)}.blobs{j}.colour == colours(varargin{3},:));
                        if isfield(st.vols{cm_handles(i)}.blobs{j},'cbar')
                            delete(st.vols{cm_handles(i)}.blobs{j}.cbar);
                        end
                        st.vols{cm_handles(i)}.blobs(j) = [];
                        break;
                    end
                end
                rm_c_menu = findobj(st.vols{cm_handles(i)}.ax{1}.cm,'Label','Remove coloured blobs');
                delete(gcbo);
                if isempty(st.vols{cm_handles(i)}.blobs)
                    st.vols{cm_handles(i)} = rmfield(st.vols{cm_handles(i)},'blobs');
                    set(rm_c_menu, 'Visible', 'off');
                end
            end
        end
        redraw_all;
        
    case 'add_c_image'
        % Add truecolored image
        cm_handles = valid_handles;
        if varargin{2} == 2, cm_handles = get_current_handle; end
        spm_input('!DeleteInputObj');
        fname = spm_select([1 Inf],'image','select image(s)');
        for k = 1:size(fname,1)
            c = spm_input(sprintf('Image %d: Colour',k),'+1','m',...
                'Red blobs|Yellow blobs|Green blobs|Cyan blobs|Blue blobs|Magenta blobs',[1 2 3 4 5 6],1);
            colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
            c_names = {'red';'yellow';'green';'cyan';'blue';'magenta'};
            hlabel = sprintf('%s (%s)',fname(k,:),c_names{c});
            for i = 1:numel(cm_handles)
                addcolouredimage(cm_handles(i),fname(k,:),colours(c,:));
                addcolourbar(cm_handles(i),numel(st.vols{cm_handles(i)}.blobs));
                c_handle    = findobj(findobj(st.vols{cm_handles(i)}.ax{1}.cm,'label','Overlay'),'Label','Remove coloured blobs');
                ch_c_handle = get(c_handle,'Children');
                set(c_handle,'Visible','on');
                %set(ch_c_handle,'Visible',on');
                item7_4_1 = uimenu(ch_c_handle(2),'Label',hlabel,'ForegroundColor',colours(c,:),...
                    'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',2,c);','UserData',c);
                if varargin{2} == 1
                    item7_4_2 = uimenu(ch_c_handle(1),'Label',hlabel,'ForegroundColor',colours(c,:),...
                        'Callback','c = get(gcbo,''UserData'');bspm_orthviews(''context_menu'',''remove_c_blobs'',1,c);',...
                        'UserData',c);
                end
            end
            redraw_all;
        end
        
    case 'setblobsmax'
        if varargin{2} == 1
            % global
            cm_handles = valid_handles;
            mx = -inf;
            for i = 1:numel(cm_handles)
                if ~isfield(st.vols{cm_handles(i)}, 'blobs'), continue, end
                for j = 1:numel(st.vols{cm_handles(i)}.blobs)
                    mx = max(mx, st.vols{cm_handles(i)}.blobs{j}.max);
                end
            end
            mx = spm_input('Maximum value', '+1', 'r', mx, 1);
            for i = 1:numel(cm_handles)
                if ~isfield(st.vols{cm_handles(i)}, 'blobs'), continue, end
                for j = 1:numel(st.vols{cm_handles(i)}.blobs)
                    st.vols{cm_handles(i)}.blobs{j}.max = mx;
                end
            end
        else
            % local (should handle coloured blobs, but not implemented yet)
            cm_handle = get_current_handle;
            colours = [1 0 0;1 1 0;0 1 0;0 1 1;0 0 1;1 0 1];
            if ~isfield(st.vols{cm_handle}, 'blobs'), return, end
            for j = 1:numel(st.vols{cm_handle}.blobs)
                if nargin < 4 || ...
                        all(st.vols{cm_handle}.blobs{j}.colour == colours(varargin{3},:))
                    mx = st.vols{cm_handle}.blobs{j}.max;
                    mx = spm_input('Maximum value', '+1', 'r', mx, 1);
                    st.vols{cm_handle}.blobs{j}.max = mx;
                end
            end
        end
        redraw_all;
end
function current_handle = get_current_handle
cm_handle      = get(gca,'UIContextMenu');
cm_handles     = get_cm_handles;
current_handle = find(cm_handles==cm_handle);
function zoom_all(zoom,res)
cm_handles = get_cm_handles;
zoom_op(zoom,res);
for i = 1:numel(cm_handles)
    z_handle = get(findobj(cm_handles(i),'label','Zoom'),'Children');
    set(z_handle,'Checked','off');
    if isinf(zoom)
        set(findobj(z_handle,'Label','Full Volume'),'Checked','on');
    elseif zoom > 0
        set(findobj(z_handle,'Label',sprintf('%dx%d mm', 2*zoom, 2*zoom)),'Checked','on');
    end % leave all unchecked if either bounding box option was chosen
end
function addcolourbar(vh,bh)
    global st
    axpos = zeros(3, 4);
    for a = 1:3
        axpos(a,:) = get(st.vols{vh}.ax{a}.ax, 'position');
    end
    cbpos = axpos(3,:); 
    cbpos(4) = cbpos(4)*.9; 
    cbpos(2) = cbpos(2) + (axpos(3,4)-cbpos(4))/2; 
    cbpos(1) = sum(cbpos([1 3])); 
    cbpos(3) = (1 - cbpos(1))/2; 
    cbpos(3) = min([cbpos(3) .30]); 
    cbpos(1) = cbpos(1) + (cbpos(3)/4); 
    yl      = [st.vols{vh}.blobs{bh}.min st.vols{vh}.blobs{bh}.max];
    yltick  = [ceil(min(yl)) floor(max(yl))];
    yltick(abs(yl) < 1) = yl(abs(yl) < 1); 
    if strcmpi(st.direct, '+/-') & min(yltick)<0
        yltick = [yltick(1) 0 yltick(2)]; 
    end
    ylab = cellnum2str(num2cell(yltick), 2); 
    st.vols{vh}.blobs{bh}.cbar = axes('Parent', st.figax, 'ycolor', st.color.fg, ...
        'position', cbpos, 'YAxisLocation', 'right', 'fontsize', 12, ...
        'ytick', yltick, 'tag', 'colorbar', ...
        'Box','on', 'YDir','normal', 'XTickLabel',[], 'XTick',[]); 
    set(st.vols{vh}.blobs{bh}.cbar, 'YTickLabel', ylab, 'fontweight', 'bold', 'fontsize', st.fonts.sz3, 'fontname', st.fonts.name); 
    if isfield(st.vols{vh}.blobs{bh},'name')
        ylabel(st.vols{vh}.blobs{bh}.name,'parent',st.vols{vh}.blobs{bh}.cbar);
    end    
function cmap = getcmap(acmapname)
% get colormap of name acmapname
if ~isempty(acmapname)
    cmap = evalin('base',acmapname,'[]');
    if isempty(cmap) % not a matrix, is .mat file?
        acmat = spm_file(acmapname, 'ext','.mat');
        if exist(acmat, 'file')
            s    = struct2cell(load(acmat));
            cmap = s{1};
        end
    end
end
if size(cmap, 2)~=3
    warning('Colormap was not an N by 3 matrix')
    cmap = [];
end
function redraw_colourbar(vh,bh,interval,cdata)
    global st
    axpos = zeros(3, 4);
    for a = 1:3
        axpos(a,:) = get(st.vols{vh}.ax{a}.ax, 'position');
    end
    cbpos = axpos(3,:); 
    cbpos(4) = cbpos(4)*.9; 
    cbpos(2) = cbpos(2) + (axpos(3,4)-cbpos(4))/2; 
    cbpos(1) = sum(cbpos([1 3])); 
    cbpos(3) = (1 - cbpos(1))/2; 
    cbpos(1) = cbpos(1) + (cbpos(3)/4);
    % only scale cdata if we have out-of-range truecolour values
    if ndims(cdata)==3 && max(cdata(:))>1
        cdata=cdata./max(cdata(:));
    end
    yl = interval;
    yltick  = [ceil(min(yl)) floor(max(yl))];
    yltick(abs(yl) < 1) = yl(abs(yl) < 1); 
    if strcmpi(st.direct, '+/-') & min(yltick)<0
        yltick = [yltick(1) 0 yltick(2)]; 
    end
    ylab = cellnum2str(num2cell(yltick), 2); 
    h = st.vols{vh}.blobs{bh}.cbar; 
    image([0 1],interval,cdata,'Parent',h);
    set(h, 'ycolor', st.color.fg, ...
        'position', cbpos, 'YAxisLocation', 'right', ...
        'ytick', yltick, ...
        'Box','on', 'YDir','normal', 'XTickLabel',[], 'XTick',[]); 
    set(h, 'YTickLabel', ylab, 'fontweight', 'bold', 'fontsize', st.fonts.sz3, 'fontname', st.fonts.name); 
    if isfield(st.vols{vh}.blobs{bh},'name')
        ylabel(st.vols{vh}.blobs{bh}.name,'parent',st.vols{vh}.blobs{bh}.cbar);
    end
function repos_start(varargin)
    if ~strcmpi(get(gcbf,'SelectionType'),'alt')
        set(gcbf,'windowbuttonmotionfcn',@repos_move, 'windowbuttonupfcn',@repos_end);
        bspm_orthviews('reposition');
    end
function repos_move(varargin)
    bspm_orthviews('reposition');
function repos_end(varargin)
    set(gcbf,'windowbuttonmotionfcn','', 'windowbuttonupfcn','');

% | BSPM_XYZREG (MODIFIED FROM SPM8 SPM_XYXREG)
% =========================================================================
function varargout = bspm_XYZreg(varargin)
% Registry for GUI XYZ locations, and point list utility functions
%
%                           ----------------
%
% PointList & voxel centre utilities...
%
% FORMAT [xyz,d] = bspm_XYZreg('RoundCoords',xyz,M,D)
% FORMAT [xyz,d] = bspm_XYZreg('RoundCoords',xyz,V)
% Rounds specified xyz location to nearest voxel centre
% xyz - (Input) 3-vector of X, Y & Z locations, in "real" co-ordinates
% M   - 4x4 transformation matrix relating voxel to "real" co-ordinates
% D   - 3 vector of image X, Y & Z dimensions (DIM)
% V   - 9-vector of image and voxel sizes, and origin [DIM,VOX,ORIGIN]'
%       M derived as [ [diag(V(4:6)), -(V(7:9).*V(4:6))]; [zeros(1,3) ,1]]
%       DIM    - D
%       VOX    - Voxel dimensions in units of "real" co-ordinates
%       ORIGIN - Origin of "real" co-ordinates in voxel co-ordinates
% xyz - (Output) co-ordinates of nearest voxel centre in "real" co-ordinates
% d   - Euclidean distance between requested xyz & nearest voxel centre
%
% FORMAT i = bspm_XYZreg('FindXYZ',xyz,XYZ)
% finds position of specified voxel in XYZ pointlist
% xyz - 3-vector of co-ordinates
% XYZ - Pointlist: 3xn matrix of co-ordinates
% i   - Column(s) of XYZ equal to xyz
%
% FORMAT [xyz,i,d] = bspm_XYZreg('NearestXYZ',xyz,XYZ)
% find nearest voxel in pointlist to specified location
% xyz - (Input) 3-vector of co-ordinates
% XYZ - Pointlist: 3xn matrix of co-ordinates
% xyz - (Output) co-ordinates of nearest voxel in XYZ pointlist
%       (ties are broken in favour of the first location in the pointlist)
% i   - Column of XYZ containing co-ordinates of nearest pointlist location
% d   - Euclidean distance between requested xyz & nearest pointlist location
%
% FORMAT d = bspm_XYZreg('Edist',xyz,XYZ)
% Euclidean distances between co-ordinates xyz & points in XYZ pointlist
% xyz - 3-vector of co-ordinates
% XYZ - Pointlist: 3xn matrix of co-ordinates
% d   - n row-vector of Euclidean distances between xyz & points of XYZ
%
%                           ----------------
% Registry functions
%
% FORMAT [hReg,xyz] = bspm_XYZreg('InitReg',hReg,M,D,xyz)
% Initialise registry in graphics object
% hReg - Handle of HandleGraphics object to build registry in. Object must
%        be un'Tag'ged and have empty 'UserData'
% M    - 4x4 transformation matrix relating voxel to "real" co-ordinates, used
%        and stored for checking validity of co-ordinates
% D    - 3 vector of image X, Y & Z dimensions (DIM), used
%        and stored for checking validity of co-ordinates
% xyz  - (Input) Initial co-ordinates [Default [0;0;0]]
%        These are rounded to the nearest voxel centre
% hReg - (Output) confirmation of registry handle
% xyz  - (Output) Current registry co-ordinates, after rounding
%
% FORMAT bspm_XYZreg('UnInitReg',hReg)
% Clear registry information from graphics object
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object.
%        Object's 'Tag' & 'UserData' are cleared
%
% FORMAT xyz = bspm_XYZreg('GetCoords',hReg)
% Get current registry co-ordinates
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% 
% FORMAT [xyz,d] = bspm_XYZreg('SetCoords',xyz,hReg,hC,Reg)
% Set co-ordinates in registry & update registered HGobjects/functions
% xyz  - (Input) desired co-ordinates
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
%        If hReg doesn't contain a registry, a warning is printed.
% hC   - Handle of caller object (to prevent circularities) [Default 0]
%        If caller object passes invalid registry handle, then bspm_XYZreg
%        attempts to blank the 'hReg' fiend of hC's 'UserData', printing
%        a warning notification.
% Reg  - Alternative nx2 cell array Registry of handles / functions
%        If specified, overrides use of registry held in hReg
%        [Default getfield(get(hReg,'UserData'),'Reg')]
% xyz  - (Output) Desired co-ordinates are rounded to nearest voxel if hC
%        is not specified, or is zero. Otherwise, caller is assummed to
%        have checked verity of desired xyz co-ordinates. Output xyz returns
%        co-ordinates actually set.
% d    - Euclidean distance between desired and set co-ordinates.
%
% FORMAT nReg = bspm_XYZreg('XReg',hReg,{h,Fcn}pairs)
% Cross registration object/function pairs with the registry, push xyz co-ords
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% h    - Handle of HandleGraphics object to be registered
%        The 'UserData' of h must be a structure with an 'Reg' field, which
%        is set to hReg, the handle of the registry (back registration)
% Fcn  - Handling function for HandleGraphics object h
%        This function *must* accept XYZ updates via the call:
%                feval(Fcn,'SetCoords',xyz,h,hReg)
%        and should *not* call back the registry with the update!
%        {h,Fcn} are appended to the registry (forward registration)
% nReg - New registry cell array: Handles are checked for validity before
%        entry. Invalid handles are omitted, generating a warning.
%
% FORMAT nReg = bspm_XYZreg('Add2Reg',hReg,{h,Fcn}pairs)
% Add object/function pairs for XYZ updates to registry (forward registration)
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% h    - Handle of HandleGraphics object to be registered
% Fcn  - Handling function for HandleGraphics object h
%        This function *must* accept XYZ updates via the call:
%                feval(Fcn,'SetCoords',xyz,h,hReg)
%        and should *not* call back the registry with the update!
%        {h,Fcn} are appended to the registry (forward registration)
% nReg - New registry cell array: Handles are checked for validity before
%        entry. Invalid handles are omitted, generating a warning.
%
% FORMAT bspm_XYZreg('SetReg',h,hReg)
% Set registry field of object's UserData (back registration)
% h    - Handle of HandleGraphics object to be registered
%        The 'UserData' of h must be a structure with an 'Reg' field, which
%        is set to hReg, the handle of the registry (back registration)
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
%
% FORMAT nReg = bspm_XYZreg('unXReg',hReg,hD1,hD2,hD3,...)
% Un-cross registration of HandleGraphics object hD
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% hD?  - Handles of HandleGraphics object to be unregistered
%        The 'UserData' of hD must be a structure with a 'Reg' field, which
%        is set to empty (back un-registration)
% nReg - New registry cell array: Registry entries with handle entry hD are 
%        removed from the registry (forward un-registration)
%        Handles not in the registry generate a warning
%
% FORMAT nReg = bspm_XYZreg('Del2Reg',hReg,hD)
% Delete HandleGraphics object hD from registry (forward un-registration)
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
% hD?  - Handles of HandleGraphics object to be unregistered
% nReg - New registry cell array: Registry entries with handle entry hD are 
%        removed from the registry. Handles not in registry generate a warning
%
% FORMAT bspm_XYZreg('UnSetReg',h)
% Unset registry field of object's UserData (back un-registration)
% h - Handle of HandleGraphics object to be unregistered
%     The 'UserData' of hD must be a structure with a 'Reg' field, which
%     is set to empty (back un-registration)
%
% FORMAT bspm_XYZreg('CleanReg',hReg)
% Clean invalid handles from registry
% hReg - Handle of 'hReg' 'Tag'ged registry HandleGraphics object
%
% FORMAT Reg = bspm_XYZreg('VReg',Reg,Warn)
% Prune invalid handles from Registry cell array
% Reg  - (Input) nx2 cell array of {handle,function} pairs
% Warn - If specified, print warning if find invalid handles
% Reg  - (Output) mx2 cell array of valid {handle,function} pairs
%
% FORMAT hReg = bspm_XYZreg('FindReg',h)
% Find/check registry object
% h    - handle of Registry, or figure containing Registry (default gcf)
%        If ischar(h), then uses spm_figure('FindWin',h) to locate named figures
% hReg - handle of confirmed registry object
%        Errors if h is not a registry or a figure containing a unique registry
%        Registry object is identified by 'hReg' 'Tag'
%_______________________________________________________________________
%
% bspm_XYZreg provides a framework for modular inter-GUI communication of
% XYZ co-orginates, and various utility functions for pointlist handling
% and rounding in voxel co-ordinates.
%
%-----------------------------------------------------------------------
%                                                           THE REGISTRY
%
% The concept of the registry is of a central entity which "knows"
% about other GUI objects holding XYZ co-ordinates, and keeps them all
% in sync. Changes to the registry's XYZ co-ordinates are passed on to
% registered functions by the registry (forward registration).
% Individual objects which can change the XYZ co-ordinates should
% therefore update the registry with the new co-ordinates (back
% registration), so that the registry can tell all registered objects
% about the new location, and a framework is provided for this.
%
% The registry is held as the 'UserData of a HandleGraphics object,
% whose handle therefore identifies the registry. The registry object
% is 'Tag'ged 'hReg' for identification (though this 'Tag' is not used
% for locating the registry, so multiple registry incarnations are
% possible). The registry object's 'UserData' is a structure containing
% the current XYZ co-ordinates, the voxel-to-co-ordinates matrix M, the
% image dimensions D, and the Registry itself. The registry is a nx2
% cell array containing n handle/function pairs.
%
% The model is that all GUI objects requiring linking to a common XYZ
% location via the registry each be identified by a HandleGraphics
% handle. This handle can be the handle of the particular instantiation
% of the GUI control itself (as is the case with the MIP-GUI of
% spm_mip_ui where the axis handle is used to identify the MIP to use);
% the handle of another HandleGraphics object associated with the GUI
% control (as is the case with the XYZ editable widgets of
% spm_results_ui where the handle of the bounding frame uicontrol is
% used); or may be 0, the handle of the root object, which allows non
% GUI functions (such as a function that just prints information) to be
% added to the registry. The registry itself thus conforms to this
% model. Each object has an associated "handling function" (so this
% function is the registry's handling function). The registry itself
% consists of object-handle/handling-function pairs.
%
% If an object and it's handling function are entered in the registry,
% then the object is said to be "forward registered", because the
% registry will now forward all location updates to that object, via
% it's handling function. The assummed syntax is:
% feval(Fcn,'SetCoords',xyz,h,hReg), where Fcn is the handling function
% for the GUI control identified by handle h, xyz are the new
% co-ordinates, and hReg is the handle of the registry.
%
% An optional extension is "back registration", whereby the GUI
% controls inform the registry of the new location when they are
% updated. All that's required is that the objects call the registry's
% 'SetCoords' function: bspm_XYZreg('SetCoords',xyz,hReg,hC), where hReg
% is the registry object's handle, and hC is the handle associated with
% the calling GUI control. The specification of the caller GUI control
% allows the registry to avoid circularities: If the object is "forward
% registered" for updates, then the registry function doesn't try to
% update the object which just updated the registry! (Similarly, the
% handle of the registry object, hReg, is passed to the handling
% function during forward XYZ updating, so that the handling function's
% 'SetCoords' facility can be constructed to accept XYZ updates from
% various sources, and only inform the registry if not called by the
% registry, and hence avoid circularities.)
%
% A framework is provided for "back" registration. Really all that is
% required is that the GUI controls know of the registry object (via
% it's handle hReg), and call the registry's 'SetCoords' facility when
% necessary. This can be done in many ways, but a simple structure is
% provided, mirroring that of the registry's operation. This framework
% assummes that the GUI controls identification object's 'UserData' is
% a structure with a field named 'hReg', which stores the handle of the
% registry (if back registered), or is empty (if not back registered,
% i.e. standalone). bspm_XYZreg provides utility functions for
% setting/unsetting this field, and for "cross registering" - that is
% both forward and back registration in one command. Cross registering
% involves adding the handle/function pair to the registry, and setting
% the registry handle in the GUI control object's 'UserData' 'hReg'
% field. It's up to the handling function to read the registry handle
% from it's objects 'UserData' and act accordingly. A simple example of
% such a function is provided in bspm_XYZreg_Ex2.m, illustrated below.
%
% SubFunctions are provided for getting and setting the current
% co-ordinates; adding and deleting handle/function pairs from the
% registry (forward registration and un-registration), setting and
% removing registry handle information from the 'hReg' field of the
% 'UserData' of a HG object (backward registration & un-registration);
% cross registration and unregistration (including pushing of current
% co-ordinates); setting and getting the current XYZ location. See the
% FORMAT statements and the example below...
%
%                           ----------------
% Example
% %-Create a window:
% F = figure;
% %-Create an object to hold the registry
% hReg = uicontrol(F,'Style','Text','String','hReg',...
%   'Position',[100 200 100 025],...
%   'FontName','Times','FontSize',14,'FontWeight','Bold',...
%   'HorizontalAlignment','Center');
% %-Setup M & D
% V = [65;87;26;02;02;04;33;53;08];
% M = [ [diag(V(4:6)), -(V(7:9).*V(4:6))]; [zeros(1,3) ,1]];
% D = V(1:3);
% %-Initialise a registry in this object, with initial co-ordinates [0;0;0]
% bspm_XYZreg('InitReg',hReg,M,D,[0;0;0])
% % (ans returns [0;0;0] confirming current co-ordinates
% %-Set co-ordinates to [10;10;10]
% bspm_XYZreg('SetCoords',[10,10,10],hReg)
% % (warns of co-ordinate rounding to [10,10,12], & returns ans as [10;10;12])
%
% %-Forward register a command window xyz reporting function: bspm_XYZreg_Ex1.m
% bspm_XYZreg('Add2Reg',hReg,0,'bspm_XYZreg_Ex1')
% % (ans returns new registry, containing just this handle/function pair
% %-Set co-ordinates to [0;10;12]
% [xyz,d] = bspm_XYZreg('SetCoords',[0,10,12],hReg);
% % (bspm_XYZreg_Ex1 called, and prints co-ordinates and handles)
% %-Have a peek at the registry information
% RD = get(hReg,'UserData')
% RD.xyz    %-The current point according to the registry
% RD.Reg    %-The nx2 cell array of handle/function pairs
%
% %-Create an example GUI XYZ control, using bspm_XYZreg_Ex2.m
% hB = bspm_XYZreg_Ex2('Create',M,D,xyz);
% % (A figure window with a button appears, whose label shows the current xyz
% %-Press the button, and enter new co-ordinates [0;0;0] in the Cmd window...
% % (...the button's internal notion of the current location is changed, but
% % (the registry isn't informed:
% bspm_XYZreg('GetCoords',hReg)
% (...returns [0;10;12])
% %-"Back" register the button
% bspm_XYZreg('SetReg',hB,hReg)
% %-Check the back registration
% if ( hReg == getfield(get(hB,'UserData'),'hReg') ), disp('yes!'), end
% %-Now press the button, and enter [0;0;0] again...
% % (...this time the registry is told, and the registry tells bspm_XYZreg_Ex1,
% % (which prints out the new co-ordinates!
% %-Forward register the button to receive updates from the registry
% nReg = bspm_XYZreg('Add2Reg',hReg,hB,'bspm_XYZreg_Ex2')
% % (The new registry is returned as nReg, showing two entries
% %-Set new registry co-ordinates to [10;10;12]
% [xyz,d] = bspm_XYZreg('SetCoords',[10;10;12],hReg);
% % (...the button updates too!
%
% %-Illustration of robustness: Delete the button & use the registry
% delete(hB)
% [xyz,d] = bspm_XYZreg('SetCoords',[10;10;12],hReg);
% % (...the invalid handle hB in the registry is ignored)
% %-Peek at the registry
% getfield(get(hReg,'UserData'),'Reg')
% %-Delete hB from the registry by "cleaning"
% bspm_XYZreg('CleanReg',hReg)
% % (...it's gone
%
% %-Make a new button and cross register
% hB = bspm_XYZreg_Ex2('Create',M,D)
% % (button created with default co-ordinates of [0;0;0]
% nReg = bspm_XYZreg('XReg',hReg,hB,'bspm_XYZreg_Ex2')
% % (Note that the registry pushes the current co-ordinates to the button
% %-Use the button & bspm_XYZreg('SetCoords'... at will!
%_______________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% Andrew Holmes, Chloe Hutton
% $Id: bspm_XYZreg.m 3664 2010-01-07 16:08:51Z volkmar $



%=======================================================================
switch lower(varargin{1}), case 'roundcoords'
%=======================================================================
% [xyz,d] = bspm_XYZreg('RoundCoords',xyz,M,D)
% [xyz,d] = bspm_XYZreg('RoundCoords',xyz,V)
if nargin<3, error('Insufficient arguments'), end
if nargin<4
    V = varargin{3};
    M = [ [diag(V(4:6)), -(V(7:9).*V(4:6))]; [zeros(1,3) ,1]];
    D = V(1:3);
else
    M = varargin{3};
    D = varargin{4};
end
    
%-Round xyz to coordinates of actual voxel centre
%-Do rounding in voxel coordinates & ensure within image size
%-Watch out for infinities!
%-----------------------------------------------------------------------
xyz  = [varargin{2}(:); 1];
xyz(isinf(xyz)) = 1e10*sign(xyz(isinf(xyz)));
rcp  = round(inv(M)*xyz);
rcp  = max([min([rcp';[D',1]]);[1,1,1,1]])';
rxyz = M*rcp;

%-Work out Euclidean distance between points xyz & rounded xyz
d = sqrt(sum((xyz-rxyz).^2));

varargout = {rxyz(1:3),d};



%=======================================================================
case 'findxyz'
%=======================================================================
% i = bspm_XYZreg('FindXYZ',xyz,XYZ)
if nargin<3, error('Insufficient arguments'), end
XYZ = varargin{3};
xyz = varargin{2};
    
%-Find XYZ = xyz
%-----------------------------------------------------------------------
i = find(all([XYZ(1,:)==xyz(1);XYZ(2,:)==xyz(2);XYZ(3,:)==xyz(3)],1));

varargout = {i};



%=======================================================================
case 'nearestxyz'
%=======================================================================
% [xyz,i,d] = bspm_XYZreg('NearestXYZ',xyz,XYZ)
if nargin<3, error('Insufficient arguments'), end
    
%-Find in XYZ nearest point to coordinates xyz (Euclidean distance) 
%-----------------------------------------------------------------------
[d,i] = min(bspm_XYZreg('Edist',varargin{2},varargin{3}));
varargout = {varargin{3}(:,i),i,d};



%=======================================================================
case 'edist'
%=======================================================================
% d = bspm_XYZreg('Edist',xyz,XYZ)
if nargin<3, error('Insufficient arguments'), end
    
%-Calculate (Euclidean) distances from pointlist co-ords to xyz
%-----------------------------------------------------------------------
varargout = {sqrt(sum([ (varargin{3}(1,:) - varargin{2}(1));...
            (varargin{3}(2,:) - varargin{2}(2));...
            (varargin{3}(3,:) - varargin{2}(3)) ].^2))};



%=======================================================================
case 'initreg'      % Initialise registry in handle h
%=======================================================================
% [hReg,xyz] = bspm_XYZreg('InitReg',hReg,M,D,xyz)
if nargin<5, xyz=[0;0;0]; else, xyz=varargin{5}; end
if nargin<4, error('Insufficient arguments'), end

D    = varargin{4};
M    = varargin{3};
hReg = varargin{2};

%-Check availability of hReg object for building a registry in
%-----------------------------------------------------------------------
if ~isempty(get(hReg,'UserData')), error('Object already has UserData...'), end
if ~isempty(get(hReg,'Tag')), error('Object already ''Tag''ed...'), end

%-Check co-ordinates are in range
%-----------------------------------------------------------------------
[xyz,d] = bspm_XYZreg('RoundCoords',xyz,M,D);
if d>0 & nargout<2, warning(sprintf('%s: Co-ords rounded to neatest voxel center: Discrepancy %.2f',mfilename,d)), end

%-Set up registry
%-----------------------------------------------------------------------
RD = struct('xyz',xyz,'M',M,'D',D,'Reg',[]);
RD.Reg = {};
set(hReg,'Tag','hReg','UserData',RD)

%-Return current co-ordinates
%-----------------------------------------------------------------------
varargout = {hReg,xyz};



%=======================================================================
case 'uninitreg'    % UnInitialise registry in handle hReg
%=======================================================================
% bspm_XYZreg('UnInitReg',hReg)
hReg = varargin{2};
if ~strcmp(get(hReg,'Tag'),'hReg'), warning('Not an XYZ registry'), return, end
set(hReg,'Tag','','UserData',[])



%=======================================================================
case 'getcoords'    % Get current co-ordinates
%=======================================================================
% xyz = bspm_XYZreg('GetCoords',hReg)
if nargin<2, hReg=bspm_XYZreg('FindReg'); else, hReg=varargin{2}; end
if ~ishandle(hReg), error('Invalid object handle'), end
if ~strcmp(get(hReg,'Tag'),'hReg'), error('Not a registry'), end
varargout = {getfield(get(hReg,'UserData'),'xyz')};



%=======================================================================
case 'setcoords'    % Set co-ordinates & update registered functions
%=======================================================================
% [xyz,d] = bspm_XYZreg('SetCoords',xyz,hReg,hC,Reg)
% d returned empty if didn't check, warning printed if d not asked for & round
% Don't check if callerhandle specified (speed)
% If Registry cell array Reg is specified, then only these handles are updated
hC=0; mfn=''; if nargin>=4
    if ~ischar(varargin{4}), hC=varargin{4}; else mfn=varargin{4}; end
end
hReg = varargin{3};

%-Check validity of hReg registry handle
%-----------------------------------------------------------------------
%-Return if hReg empty, in case calling objects functions don't check isempty
if isempty(hReg), return, end
%-Check validity of hReg registry handle, correct calling objects if necc.
if ~ishandle(hReg)
    str = sprintf('%s: Invalid registry handle (%.4f)',mfilename,hReg);
    if hC>0
        %-Remove hReg from caller
        bspm_XYZreg('SetReg',hC,[])
        str = [str,sprintf('\n\t\t\t...removed from caller (%.4f)',hC)];
    end
    warning(str)
    return
end
xyz  = varargin{2};
RD      = get(hReg,'UserData');

%-Check validity of coords only when called without a caller handle
%-----------------------------------------------------------------------
if hC<=0
    [xyz,d] = bspm_XYZreg('RoundCoords',xyz,RD.M,RD.D);
    if d>0 & nargout<2, warning(sprintf(...
        '%s: Co-ords rounded to neatest voxel center: Discrepancy %.2f',...
        mfilename,d)), end
else
    d = 0;
end

%-Sort out valid handles, eliminate caller handle, update co-ords with
% registered handles via their functions
%-----------------------------------------------------------------------
if nargin<5
    RD.Reg = bspm_XYZreg('VReg',RD.Reg);
    Reg    = RD.Reg;
else
    Reg = bspm_XYZreg('VReg',varargin{5});
end
if hC>0 & length(Reg), Reg(find([Reg{:,1}]==varargin{4}),:) = []; end
for i = 1:size(Reg,1)
    feval(Reg{i,2},'SetCoords',xyz,Reg{i,1},hReg);
end

%-Update registry (if using hReg) with location & cleaned Reg cellarray
%-----------------------------------------------------------------------
if nargin<5
    RD.xyz  = xyz;
    set(hReg,'UserData',RD)
end

varargout = {xyz,d};
if ~strcmp(mfn,'spm_graph')
    sHdl=findobj(0,'Tag','SPMGraphSatelliteFig');
    axHdl=findobj(sHdl,'Type','axes','Tag','SPMGraphSatelliteAxes');
    %tag for true axis, as legend is of type axis, too
    for j=1:length(axHdl)
        autoinp=get(axHdl(j),'UserData');
        if ~isempty(autoinp), spm_graph([],[],hReg,axHdl(j)); end
    end
end


%=======================================================================
case 'xreg'     % Cross register object handles & functions
%=======================================================================
% nReg = bspm_XYZreg('XReg',hReg,{h,Fcn}pairs)
if nargin<4, error('Insufficient arguments'), end
hReg = varargin{2};

%-Quick check of registry handle
%-----------------------------------------------------------------------
if isempty(hReg),   warning('Empty registry handle'), return, end
if ~ishandle(hReg), warning('Invalid registry handle'), return, end

%-Condition nReg cell array & check validity of handles to be registered
%-----------------------------------------------------------------------
nReg = varargin(3:end);
if mod(length(nReg),2), error('Registry items must be in pairs'), end
if length(nReg)>2, nReg = reshape(nReg,length(nReg)/2,2)'; end
nReg = bspm_XYZreg('VReg',nReg,'Warn');

%-Set hReg registry link for registry candidates (Back registration)
%-----------------------------------------------------------------------
for i = 1:size(nReg,1)
    bspm_XYZreg('SetReg',nReg{i,1},hReg);
end

%-Append registry candidates to existing registry & write back to hReg
%-----------------------------------------------------------------------
RD     = get(hReg,'UserData');
Reg    = RD.Reg;
Reg    = cat(1,Reg,nReg);
RD.Reg = Reg;
set(hReg,'UserData',RD)

%-Synch co-ordinates of newly registered objects
%-----------------------------------------------------------------------
bspm_XYZreg('SetCoords',RD.xyz,hReg,hReg,nReg);

varargout = {Reg};



%=======================================================================
case 'add2reg'      % Add handle(s) & function(s) to registry
%=======================================================================
% nReg = bspm_XYZreg('Add2Reg',hReg,{h,Fcn}pairs)
if nargin<4, error('Insufficient arguments'), end
hReg = varargin{2};

%-Quick check of registry handle
%-----------------------------------------------------------------------
if isempty(hReg),   warning('Empty registry handle'), return, end
if ~ishandle(hReg), warning('Invalid registry handle'), return, end

%-Condition nReg cell array & check validity of handles to be registered
%-----------------------------------------------------------------------
nReg = varargin(3:end);
if mod(length(nReg),2), error('Registry items must be in pairs'), end
if length(nReg)>2, nReg = reshape(nReg,length(nReg)/2,2)'; end
nReg = bspm_XYZreg('VReg',nReg,'Warn');

%-Append to existing registry & put back in registry object
%-----------------------------------------------------------------------
RD     = get(hReg,'UserData');
Reg    = RD.Reg;
Reg    = cat(1,Reg,nReg);
RD.Reg = Reg;
set(hReg,'UserData',RD)

varargout = {Reg};



%=======================================================================
case 'setreg'           %-Set registry field of object's UserData
%=======================================================================
% bspm_XYZreg('SetReg',h,hReg)
if nargin<3, error('Insufficient arguments'), end
h    = varargin{2};
hReg = varargin{3};
if ( ~ishandle(h) | h==0 ), return, end
UD = get(h,'UserData');
if ~isstruct(UD) | ~any(strcmp(fieldnames(UD),'hReg'))
    error('No UserData structure with hReg field for this object')
end
UD.hReg = hReg;
set(h,'UserData',UD)



%=======================================================================
case 'unxreg'       % Un-cross register object handles & functions
%=======================================================================
% nReg = bspm_XYZreg('unXReg',hReg,hD1,hD2,hD3,...)
if nargin<3, error('Insufficient arguments'), end
hD   = [varargin{3:end}];
hReg = varargin{2};

%-Get Registry information
%-----------------------------------------------------------------------
RD         = get(hReg,'UserData');
Reg        = RD.Reg;

%-Find registry entires to delete
%-----------------------------------------------------------------------
[null,i,e] = intersect([Reg{:,1}],hD);
hD(e)      = [];
dReg       = bspm_XYZreg('VReg',Reg(i,:));
Reg(i,:)   = [];
if length(hD), warning('Not all handles were in registry'), end

%-Write back new registry
%-----------------------------------------------------------------------
RD.Reg = Reg;
set(hReg,'UserData',RD)

%-UnSet hReg registry link for hD's still existing (Back un-registration)
%-----------------------------------------------------------------------
for i = 1:size(dReg,1)
    bspm_XYZreg('SetReg',dReg{i,1},[]);
end

varargout = {Reg};



%=======================================================================
case 'del2reg'      % Delete handle(s) & function(s) from registry
%=======================================================================
% nReg = bspm_XYZreg('Del2Reg',hReg,hD)
if nargin<3, error('Insufficient arguments'), end
hD   = [varargin{3:end}];
hReg = varargin{2};

%-Get Registry information
%-----------------------------------------------------------------------
RD         = get(hReg,'UserData');
Reg        = RD.Reg;

%-Find registry entires to delete
%-----------------------------------------------------------------------
[null,i,e] = intersect([Reg{:,1}],hD);
Reg(i,:)   = [];
hD(e)      = [];
if length(hD), warning('Not all handles were in registry'), end

%-Write back new registry
%-----------------------------------------------------------------------
RD.Reg = Reg;
set(hReg,'UserData',RD)

varargout = {Reg};



%=======================================================================
case 'unsetreg'         %-Unset registry field of object's UserData
%=======================================================================
% bspm_XYZreg('UnSetReg',h)
if nargin<2, error('Insufficient arguments'), end
bspm_XYZreg('SetReg',varargin{2},[])



%=======================================================================
case 'cleanreg'     % Clean invalid handles from registry
%=======================================================================
% bspm_XYZreg('CleanReg',hReg)
%if ~strcmp(get(hReg,'Tag'),'hReg'), error('Not a registry'), end
hReg = varargin{2};
RD = get(hReg,'UserData');
RD.Reg = bspm_XYZreg('VReg',RD.Reg,'Warn');
set(hReg,'UserData',RD)


%=======================================================================
case 'vreg'     % Prune invalid handles from registry cell array
%=======================================================================
% Reg = bspm_XYZreg('VReg',Reg,Warn)
if nargin<3, Warn=0; else, Warn=1; end
Reg = varargin{2};
if isempty(Reg), varargout={Reg}; return, end
i = find(~ishandle([Reg{:,1}]));
%-***check existance of handling functions : exist('','file')?
if Warn & length(i), warning([...
    sprintf('%s: Disregarding invalid registry handles:\n\t',...
        mfilename),sprintf('%.4f',Reg{i,1})]), end
Reg(i,:)  = [];
varargout = {Reg};



%=======================================================================
case 'findreg'          % Find/check registry object
%=======================================================================
% hReg = bspm_XYZreg('FindReg',h)
if nargin<2, h=get(0,'CurrentFigure'); else, h=varargin{2}; end
if ischar(h), h=spm_figure('FindWin',h); end
if ~ishandle(h), error('invalid handle'), end
if ~strcmp(get(h,'Tag'),'hReg'), h=findobj(h,'Tag','hReg'); end
if isempty(h), error('Registry object not found'), end
if length(h)>1, error('Multiple registry objects found'), end
varargout = {h};

%=======================================================================
otherwise
%=======================================================================
warning('Unknown action string')

%=======================================================================
end

% | PEAK_NII (MODIFIED)
% =========================================================================
function [voxels, regions, invar]=peak_nii(image,mapparameters)
%%
% peak_nii will write out the maximum T (or F) of the local maxima that are
% not closer than a specified separation distance.  
% SPM=0: Those that are closer are collapsed based on the COG using number 
%   of voxels at each collapsing point. The maximum T 
%   (or F) is retained. This program should be similar to peak_4dfp in use at
%   WashU (although I haven't seen their code).
% SPM=1: Eliminates the peaks closer than a specified distance to mimic
%   result tables.
%
% INPUTS:
% image string required. This should be a nii or img file.
% mapparameters is either a .mat file or a pre-load structure with the
% following fields:
%           out: output prefix, default is to define using imagefile
%          sign: 'pos' or 'neg', default is 'pos' NOTE: only can do one
%                direction at a time
%          type: statistic type, 'T' or 'F' or 'none'
%      voxlimit: number of peak voxels in image
%    separation: distance to collapse or eliminate peaks
%           SPM: 0 or 1, see above for details
%          conn: connectivity radius, either 6,18, or 26
%       cluster: cluster extent threshold in voxels
%          mask: optional to mask your data
%           df1: numerator degrees of freedom for T/F-test (if 0<thresh<1)
%           df2: denominator degrees of freedom for F-test (if 0<thresh<1)
%       nearest: 0 or 1, 0 for leaving some clusters/peaks undefined, 1 for finding the
%                nearest label
%         label: optional to label clusters, options are 'aal_MNI_V4';
%                'Nitschke_Lab'; FSL ATLASES: 'JHU_tracts', 'JHU_whitematter',
%                'Thalamus', 'Talairach', 'MNI', 'HarvardOxford_cortex', 'Cerebellum-flirt', 'Cerebellum-fnirt', and 'Juelich'. 
%                'HarvardOxford_subcortical' is not available at this time because
%                the labels don't match the image.
%                Other atlas labels may be added in the future
%        thresh: T/F statistic or p-value to threshold the data or 0
%
% OUTPUTS:
%   voxels  -- table of peaks
%       cell{1}-
%         col. 1 - Cluster size
%         col. 2 - T/F-statistic
%         col. 3 - X coordinate
%         col. 4 - Y coordinate
%         col. 5 - Z coordinate
%         col. 6 - number of peaks collapsed
%         col. 7 - sorted cluster number
%       cell{2}- region names
%   regions -- region of each peak -- optional
%
% NIFTI FILES SAVED:
%   *_clusters.nii:                     
%                               contains the clusters and their numbers (column 7)
%   (image)_peaks_date_thresh*_cluster*.nii:             
%                               contains the thresholded data
%   (image)_peaks_date_thresh*_cluster*peaknumber.nii:   
%                               contains the peaks of the data,
%                               peaks are numbered by their order
%                               in the table (voxels)
%   (image)_peaks_date_thresh*_cluster*peakcluster.nii:  
%                               contains the peaks of the data,
%                               peaks are numbered by their cluster (column 7)
%   *(image) is the image name with the the path or extension
%
% MAT-FILES SAVED:
%   Peak_(image)_peaks_date.mat:        contains voxelsT variable and regions, if applicable 
%   (image)_peaks_date_structure:       contains parameter variable with
%                                       parameters used
%   *(image) is the image name with the the path or extension
%
% EXAMPLE: voxels=peak_nii('imagename',mapparameters)
%
% License:
%   Copyright (c) 2011, Donald G. McLaren and Aaron Schultz
%   All rights reserved.
%
%    Redistribution, with or without modification, is permitted provided that the following conditions are met:
%    1. Redistributions must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in the
%        documentation and/or other materials provided with the distribution.
%    2. All advertising materials mentioning features or use of this software must display the following acknowledgement:
%        This product includes software developed by the Harvard Aging Brain Project.
%    3. Neither the Harvard Aging Brain Project nor the
%        names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
%    4. You are not permitted under this Licence to use these files
%        commercially. Use for which any financial return is received shall be defined as commercial use, and includes (1) integration of all 	
%        or part of the source code or the Software into a product for sale or license by or on behalf of Licensee to third parties or (2) use 	
%        of the Software or any derivative of it for research with the final aim of developing software products for sale or license to a third 	
%        party or (3) use of the Software or any derivative of it for research with the final aim of developing non-software products for sale 
%        or license to a third party, or (4) use of the Software to provide any service to an external organisation for which payment is received.
%
%   THIS SOFTWARE IS PROVIDED BY DONALD G. MCLAREN (mclaren@nmr.mgh.harvard.edu) AND AARON SCHULTZ (aschultz@nmr.mgh.harvard.edu)
%   ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
%   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
%   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
%   USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
%   peak_nii.v3 -- Last modified on 12/10/2010 by Donald G. McLaren, PhD
%   (mclaren@nmr.mgh.harvard.edu)
%   Wisconsin Alzheimer's Disease Research Center - Imaging Core, Univ. of
%   Wisconsin - Madison
%   Neuroscience Training Program and Department of Medicine, Univ. of
%   Wisconsin - Madison
%   GRECC, William S. Middleton Memorial Veteren's Hospital, Madison, WI
%   GRECC, Bedford VAMC
%   Department of Neurology, Massachusetts General Hospital and Havard
%   Medical School
%
%   In accordance with the licences of the atlas sources as being distibuted solely
%   for non-commercial use; neither this program, also soley being distributed for non-commercial use,
%   nor the atlases containe herein should therefore not be used for commercial purposes; for such
%   purposes please contact the primary co-ordinator for the relevant
%   atlas:
%       Harvard-Oxford: steve@fmrib.ox.ac.uk
%       JHU: susumu@mri.jhu.edu
%       Juelich: S.Eickhoff@fz-juelich.de
%       Thalamus: behrens@fmrib.ox.ac.uk
%       Cerebellum: j.diedrichsen@bangor.ac.uk
%       AAL_MNI_V4: maldjian@wfubmc.edu and/or bwagner@wfubmc.edu
%
%   For the program in general, please contact mclaren@nmr.mgh.harvard.edu
%

global st

%% make sure image is char
if iscell(image), image = char(image); end

%% Check inputs
if exist(image,'file')==2
    I1=spm_vol(image);
    infoI1=I1;
    [I1,voxelcoord]=spm_read_vols(I1);
    if nansum(nansum(nansum(abs(I1))))==0
        error(['Error: ' image ' is all zeros or all NaNs'])        
    end
else
    error(['File ' image ' does not exist'])
end
try
if exist(mapparameters,'file')==2
    mapparameters=load(mapparameters);
end
end
invar=peak_nii_inputs(mapparameters,infoI1.fname,nargout);
if strcmpi(invar.sign,'neg')
    I1=-1.*I1;
end
I=I1; 

% Find significant voxels
ind=find(I>invar.thresh);
if isempty(ind)
    voxels=[]; regions={};
    display(['NO MAXIMA ABOVE ' num2str(invar.thresh) '.'])
    return
else
   [L(1,:),L(2,:),L(3,:)]=ind2sub(infoI1.dim,ind);
end

% Cluster signficant voxels
A=peakcluster(L,invar.conn,infoI1); % A is the cluster of each voxel
% A=transpose(A);
n=hist(A,1:max(A));
for ii=1:size(A,1)
    if n(A(ii))<invar.cluster % removes clusters smaller than extent threshold
        A(ii,1:2)=NaN;
    else
        A(ii,1:2)=[n(A(ii)) A(ii,1)];
    end
end

% Combine A (cluster labels) and L (voxel indicies)
L=L';
A(:,3:5)=L(:,1:3);

% Remove voxels that are in small clusters
A(any(isnan(A),2),:) = [];

% Save clusters
[T, Iclust]=peakcluster(transpose(A(:,3:5)),invar.conn,infoI1);
A(:,2)=T(:,1); clear T

% Find all peaks, only look at current cluster to determine the peak
Ic=zeros(infoI1.dim(1),infoI1.dim(2),infoI1.dim(3),max(A(:,2)));
for ii=1:max(A(:,2))
    Ic(:,:,:,ii)=I.*(Iclust==ii);
end
N=0;
voxelsT=zeros(size(A,1),7);
for ii=1:size(A,1)
    if A(ii,3)==1 || A(ii,4)==1 || A(ii,5)==1 || A(ii,3)==size(Ic,1) || A(ii,4)==size(Ic,2) || A(ii,5)==size(Ic,3)
    else
        if I(A(ii,3),A(ii,4),A(ii,5))==max(max(max(Ic(A(ii,3)-1:A(ii,3)+1,A(ii,4)-1:A(ii,4)+1,A(ii,5)-1:A(ii,5)+1,A(ii,2)))))
            N=N+1;
            voxind=sub2ind(infoI1.dim,A(ii,3),A(ii,4),A(ii,5));
            voxelsT(N,1)=A(ii,1);
            voxelsT(N,2)=I(voxind);
            voxelsT(N,3)=voxelcoord(1,voxind);
            voxelsT(N,4)=voxelcoord(2,voxind);
            voxelsT(N,5)=voxelcoord(3,voxind);
            voxelsT(N,6)=1;
            voxelsT(N,7)=A(ii,2);
        end
    end
end

%Remove empty rows
voxelsT=voxelsT(any(voxelsT'),:);
if isempty(voxelsT)
    voxels=[]; regions={};
    display(['NO CLUSTERS LARGER THAN ' num2str(invar.cluster) ' voxels.'])
    return
end

%Check number of peaks
if size(voxelsT,1)>invar.voxlimit
    voxelsT=sortrows(voxelsT,-2);
    voxelsT=voxelsT(1:invar.voxlimit,:); % Limit peak voxels to invar.voxlimit
end

% Sort table by cluster w/ max T then by T value within cluster (negative
% data was inverted at beginning, so we are always looking for the max).
uniqclust=unique(voxelsT(:,7));
maxT=zeros(length(uniqclust),2);
for ii=1:length(uniqclust)
    maxT(ii,1)=uniqclust(ii);
    maxT(ii,2)=max(voxelsT(voxelsT(:,7)==uniqclust(ii),2));
end
maxT=sortrows(maxT,-2);
for ii=1:size(maxT,1)
    voxelsT(voxelsT(:,7)==maxT(ii,1),8)=ii;
end
voxelsT=sortrows(voxelsT,[8 -2]);
[cluster,uniq,ind]=unique(voxelsT(:,8)); % get rows of each cluster

%Collapse or elimintate peaks closer than a specified distance
voxelsF=zeros(size(voxelsT,1),size(voxelsT,2));
nn=[1 zeros(1,length(cluster)-1)];
for numclust=1:length(cluster)
    Distance=eps;
    voxelsC=voxelsT(ind==numclust,:);
    while min(min(Distance(Distance>0)))<invar.separation
            [voxelsC,Distance]=vox_distance(voxelsC);
            minD=min(min(Distance(Distance>0)));
            if minD<invar.separation
               min_ind=find(Distance==(min(min(Distance(Distance>0)))));
               [ii,jj]=ind2sub(size(Distance),min_ind(1));
               if invar.SPM==1
                    voxelsC(ii,:)=NaN; % elimate peak
               else
                    voxelsC(jj,1)=voxelsC(jj,1);
                    voxelsC(jj,2)=voxelsC(jj,2);
                    voxelsC(jj,3)=((voxelsC(jj,3).*voxelsC(jj,6))+(voxelsC(ii,3).*voxelsC(ii,6)))/(voxelsC(jj,6)+voxelsC(ii,6)); % avg coordinate
                    voxelsC(jj,4)=((voxelsC(jj,4).*voxelsC(jj,6))+(voxelsC(ii,4).*voxelsC(ii,6)))/(voxelsC(jj,6)+voxelsC(ii,6)); % avg coordinate
                    voxelsC(jj,5)=((voxelsC(jj,5).*voxelsC(jj,6))+(voxelsC(ii,5).*voxelsC(ii,6)))/(voxelsC(jj,6)+voxelsC(ii,6)); % avg coordinate
                    voxelsC(jj,6)=voxelsC(jj,6)+voxelsC(ii,6);
                    voxelsC(jj,7)=voxelsC(jj,7);
                    voxelsC(jj,8)=voxelsC(jj,8);
                    voxelsC(ii,:)=NaN; % eliminate second peak
               end
               voxelsC(any(isnan(voxelsC),2),:) = [];
            end
    end
    try
        nn(numclust+1)=nn(numclust)+size(voxelsC,1);
    end
    voxelsF(nn(numclust):nn(numclust)+size(voxelsC,1)-1,:)=voxelsC;
end
voxelsT=voxelsF(any(voxelsF'),:);
clear voxelsF voxelsC nn

% Modify T-values for negative
if strcmpi(invar.sign,'neg')
    voxelsT(:,2)=-1*voxelsT(:,2);
end
voxelsT(:,7)=[];

% Label Peaks
allxyz = voxelsT(:,3:5);
regionname = cell(size(allxyz,1),1); 
for i = 1:size(allxyz,1)
    xyzidx      = bspm_XYZreg('FindXYZ', allxyz(i,:), st.ol.XYZmm0); 
    regionidx   = st.ol.atlas0(xyzidx);
    if regionidx
        regionname{i} = st.ol.atlaslabels.label{st.ol.atlaslabels.id==regionidx};
    else
        regionname{i} = 'No Label'; 
    end
end
voxels = [regionname num2cell(voxelsT(:,1:5))]; 
function [N,Distance] = vox_distance(voxelsT)
% vox_distance compute the distance between local maxima in an image
% The input is expected to be an N-M matrix with columns 2,3,4 being X,Y,Z
% coordinates
%
% pdist is only available with Statistics Toolbox in recent versions of
% MATLAB, thus, the slower code is secondary if the toolbox is unavailable.
% Speed difference is dependent on cluster sizes, 3x at 1000 peaks.
N=sortrows(voxelsT,-1);
try
    Distance=squareform(pdist(N(:,3:5)));
catch
    Distance = zeros(size(N,1),size(N,1));
    for ii = 1:size(N,1);
        TmpD = zeros(size(N,1),3);
        for kk = 1:3;
            TmpD(:,kk) = (N(:,kk+2)-N(ii,kk+2)).^2;
        end
        TmpD = sqrt(sum(TmpD,2));
        Distance(:,ii) = TmpD;
    end
end
%Distance=zeros(length(N(:,1)),length(N(:,1)))*NaN;
%for ii=1:length(N(:,1))
%    for jj=ii+1:length(N(:,1))
%           Distance(ii,jj)=((N(jj,2)-N(ii,2)).^2)+((N(jj,3)-N(ii,3)).^2)+((N(jj,4)-N(ii,4)).^2);
%    end
%end
return
function [A, vol]=peakcluster(L,conn,infoI1)
    dim = infoI1.dim;
    vol = zeros(dim(1),dim(2),dim(3));
    indx = sub2ind(dim,L(1,:)',L(2,:)',L(3,:)');
    vol(indx) = 1;
    [cci,num] = spm_bwlabel(vol,conn);
    A = cci(indx');
    A=transpose(A);
    L=transpose(L);
    A(:,2:4)=L(:,1:3);
    vol=zeros(dim(1),dim(2),dim(3));
    for ii=1:size(A,1)
        vol(A(ii,2),A(ii,3),A(ii,4))=A(ii,1);
    end
function outstructure=peak_nii_inputs(instructure,hdrname,outputargs)
% Checks whether inputs are valid or not.
%   
%   ppi_nii_inputs.v2 last modified by Donald G. McLaren, PhD
%   (mclaren@nmr.mgh.harvard.edu)
%   GRECC, Bedford VAMC
%   Department of Neurology, Massachusetts General Hospital and Havard
%   Medical School
%
% License:
%   Copyright (c) 2011, Donald G. McLaren and Aaron Schultz
%   All rights reserved.
%
%    Redistribution, with or without modification, is permitted provided that the following conditions are met:
%    1. Redistributions must reproduce the above copyright
%        notice, this list of conditions and the following disclaimer in the
%        documentation and/or other materials provided with the distribution.
%    2. All advertising materials mentioning features or use of this software must display the following acknowledgement:
%        This product includes software developed by the Harvard Aging Brain Project.
%    3. Neither the Harvard Aging Brain Project nor the
%        names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
%    4. You are not permitted under this Licence to use these files
%        commercially. Use for which any financial return is received shall be defined as commercial use, and includes (1) integration of all 	
%        or part of the source code or the Software into a product for sale or license by or on behalf of Licensee to third parties or (2) use 	
%        of the Software or any derivative of it for research with the final aim of developing software products for sale or license to a third 	
%        party or (3) use of the Software or any derivative of it for research with the final aim of developing non-software products for sale 
%        or license to a third party, or (4) use of the Software to provide any service to an external organisation for which payment is received.
%
%   THIS SOFTWARE IS PROVIDED BY DONALD G. MCLAREN (mclaren@nmr.mgh.harvard.edu) AND AARON SCHULTZ (aschultz@nmr.mgh.harvard.edu)
%   ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
%   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
%   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
%   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
%   TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
%   USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%   
%   In accordance with the licences of the atlas sources as being distibuted solely
%   for non-commercial use; neither this program, also soley being distributed for non-commercial use,
%   nor the atlases containe herein should therefore not be used for commercial purposes; for such
%   purposes please contact the primary co-ordinator for the relevant
%   atlas:
%       Harvard-Oxford: steve@fmrib.ox.ac.uk
%       JHU: susumu@mri.jhu.edu
%       Juelich: S.Eickhoff@fz-juelich.de
%       Thalamus: behrens@fmrib.ox.ac.uk
%       Cerebellum: j.diedrichsen@bangor.ac.uk
%       AAL_MNI_V4: maldjian@wfubmc.edu and/or bwagner@wfubmc.edu
%
%   For the program in general, please contact mclaren@nmr.mgh.harvard.edu
%
%   Change Log:
%     4/11/2001: Allows threshold to be -Inf

%% Format input instructure
while numel(fields(instructure))==1
    F=fieldnames(instructure);
    instructure=instructure.(F{1}); %Ignore coding error flag.
end

%% outfile
try
    outstructure.out=instructure.out;
    if isempty(outstructure.out)
        vardoesnotexist; % triggers catch statement
    end
catch
    [path,file]=fileparts(hdrname);
    if ~isempty(path)
        outstructure.out=[path filesep file '_peaks_' date];
    else
        outstructure.out=[file '_peaks_' date];
    end
end

%% sign of data
try
    outstructure.sign=instructure.sign;
    if ~strcmpi(outstructure.sign,'pos') && ~strcmpi(outstructure.sign,'neg')
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.sign='pos';
end

%% threshold
try
    outstructure.thresh=instructure.thresh;
    if ~isnumeric(outstructure.thresh)
        vardoesnotexist; % triggers catch statement
    end
    if outstructure.thresh<0
        if strcmpi(outstructure.sign,'neg')  
            outstructure.thresh=outstructure.thresh*-1;
        elseif outstructure.thresh==-Inf
        else
            vardoesnotexist; % triggers catch statement
        end
    end
catch
    outstructure.thresh=0;
end

%% statistic type (F or T)
try 
    outstructure.type=instructure.type;
    if ~strcmpi(outstructure.type,'T') && ~strcmpi(outstructure.type,'F') && ~strcmpi(outstructure.type,'none') && ~strcmpi(outstructure.type,'Z')
        vardoesnotexist; % triggers catch statement
    end
catch
    if outstructure.thresh<1 && outstructure.thresh>0
        error(['Statistic must defined using: ' instructure.type])
    else
        outstructure.type='none';
    end
end

%% voxel limit
try
    outstructure.voxlimit=instructure.voxlimit;
    if ~isnumeric(outstructure.voxlimit) || outstructure.voxlimit<0
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.voxlimit=1000;
end

%% separation distance for peaks
try
    outstructure.separation=instructure.separation;
    if ~isnumeric(outstructure.separation) || outstructure.separation<0
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.separation=20;
end

%% Output peaks or collapse peaks within a cluster (0 collapse peaks closer
% than separation distance, 1 remove peaks closer than separation distance
% to mirror SPM)
try
    outstructure.SPM=instructure.SPM;
    if ~isnumeric(outstructure.SPM) || (outstructure.SPM~=0 && outstructure.SPM~=1)
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.SPM=1;
end
%% Connectivity radius
try
    outstructure.conn=instructure.conn;
    if ~isnumeric(outstructure.conn) || (outstructure.conn~=6 && outstructure.conn~=18 && outstructure.conn~=26)
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.conn=18;
end
%% Cluster extent threshold
try
    outstructure.cluster=instructure.cluster;
    if ~isnumeric(outstructure.cluster) || outstructure.cluster<0
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.cluster=0;
end
%% mask file
try
    outstructure.mask=instructure.mask;
    if ~isempty(outstructure.mask) && ~exist(outstructure.mask,'file')
        vardoesnotexist; % triggers catch statement
    end
catch
    outstructure.mask={};
end

%% degrees of freedom numerator
try
    outstructure.df1=instructure.df1;
    if ~isnumeric(outstructure.df1) || outstructure.df1<1
        vardoesnotexist; % triggers catch statement
    end
catch
    if (strcmpi(outstructure.type,'T') || strcmpi(outstructure.type,'F')) && (outstructure.thresh>0 && outstructure.thresh<1)
        disp('Using numerator degrees of freedom in image header')
        tmp = instructure.df1;
        hdr = spm_vol(hdrname);
        d = hdr.descrip;
        pos1 = regexp(d,'[','ONCE');
        pos2 = regexp(d,']','ONCE');
        tmpdf = str2num(d(pos1+1:pos2-1));
        outstructure.df1 = tmpdf;
    else
    outstructure.df1=[];
    end
end

%% degrees of freedom denominator
try
    outstructure.df2=instructure.df2;
    if ~isnumeric(outstructure.df2) || outstructure.df2<1
        vardoesnotexist; % triggers catch statement
    end
catch
    if (strcmpi(outstructure.type,'F')) && (outstructure.thresh>0 && outstructure.thresh<1)
        error('degrees of freedom numerator must be defined using df2 field; can be gotten from SPM')
    else
    outstructure.df2=[];
    end
end

%% Make threshold a non-decimal
if (strcmpi(outstructure.type,'T') || strcmpi(outstructure.type,'F') || strcmpi(outstructure.type,'Z')) && (outstructure.thresh>0 && outstructure.thresh<1)
    if strcmpi(outstructure.type,'T')
        outstructure.thresh = spm_invTcdf(1-outstructure.thresh,outstructure.df1);
    elseif strcmpi(outstructure.type,'F')
        outstructure.thresh = spm_invFcdf(1-outstructure.thresh,outstructure.df1,outstructure.df2);
    else 
        outstructure.thresh=norminv(1-outstructure.thresh,0,1);
    end
end
parameters=outstructure;
try
	parameters.label=instructure.label;
end
try
	parameters.nearest=instructure.nearest;
end

% | NAN SUITE
% =========================================================================
function y = nanmean(x,dim)
% FORMAT: Y = NANMEAN(X,DIM)
% 
%    Average or mean value ignoring NaNs
%
%    This function enhances the functionality of NANMEAN as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANMEAN(X,DIM) calculates the mean along any dimension of the N-D
%    array X ignoring NaNs.  If DIM is omitted NANMEAN averages along the
%    first non-singleton dimension of X.
%
%    Similar replacements exist for NANSTD, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MEAN

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:13 $

if isempty(x)
	y = NaN;
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

% Replace NaNs with zeros.
nans = isnan(x);
x(isnan(x)) = 0; 

% denominator
count = size(x,dim) - sum(nans,dim);

% Protect against a  all NaNs in one dimension
i = find(count==0);
count(i) = ones(size(i));

y = sum(x,dim)./count;
y(i) = i + NaN;
function y = nanmedian(x,dim)
% FORMAT: Y = NANMEDIAN(X,DIM)
% 
%    Median ignoring NaNs
%
%    This function enhances the functionality of NANMEDIAN as distributed
%    in the MATLAB Statistics Toolbox and is meant as a replacement (hence
%    the identical name).  
%
%    NANMEDIAN(X,DIM) calculates the mean along any dimension of the N-D
%    array X ignoring NaNs.  If DIM is omitted NANMEDIAN averages along the
%    first non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANSTD, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MEDIAN

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.2 $ $Date: 2007/07/30 17:19:19 $

if isempty(x)
	y = [];
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

siz  = size(x);
n    = size(x,dim);

% Permute and reshape so that DIM becomes the row dimension of a 2-D array
perm = [dim:max(length(size(x)),dim) 1:dim-1];
x = reshape(permute(x,perm),n,prod(siz)/n);


% force NaNs to bottom of each column
x = sort(x,1);

% identify and replace NaNs
nans = isnan(x);
x(isnan(x)) = 0;

% new dimension of x
[n m] = size(x);

% number of non-NaN element in each column
s = size(x,1) - sum(nans);
y = zeros(size(s));

% now calculate median for every element in y
% (does anybody know a more eefficient way than with a 'for'-loop?)
for i = 1:length(s)
	if rem(s(i),2) & s(i) > 0
		y(i) = x((s(i)+1)/2,i);
	elseif rem(s(i),2)==0 & s(i) > 0
		y(i) = (x(s(i)/2,i) + x((s(i)/2)+1,i))/2;
	end
end

% Protect against a column of NaNs
i = find(y==0);
y(i) = i + nan;

% permute and reshape back
siz(dim) = 1;
y = ipermute(reshape(y,siz(perm)),perm);
function y = nanstd(x,flag,dim)
% FORMAT: Y = NANSTD(X,FLAG,DIM)
% 
%    Standard deviation ignoring NaNs
%
%    This function enhances the functionality of NANSTD as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANSTD(X,DIM) calculates the standard deviation along any dimension of
%    the N-D array X ignoring NaNs.  
%
%    NANSTD(X,DIM,0) normalizes by (N-1) where N is SIZE(X,DIM).  This make
%    NANSTD(X,DIM).^2 the best unbiased estimate of the variance if X is
%    a sample of a normal distribution. If omitted FLAG is set to zero.
%    
%    NANSTD(X,DIM,1) normalizes by N and produces the square root of the
%    second moment of the sample about the mean.
%
%    If DIM is omitted NANSTD calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.
%
%    See also STD

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:15 $

if isempty(x)
	y = NaN;
	return
end
if nargin < 3
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1; 
	end	  
end
if nargin < 2
	flag = 0;
end




% Find NaNs in x and nanmean(x)
nans = isnan(x);
avg = nanmean(x,dim);

% create array indicating number of element 
% of x in dimension DIM (needed for subtraction of mean)
tile = ones(1,max(ndims(x),dim));
tile(dim) = size(x,dim);

% remove mean
x = x - repmat(avg,tile);

count = size(x,dim) - sum(nans,dim);

% Replace NaNs with zeros.
x(isnan(x)) = 0; 


% Protect against a  all NaNs in one dimension
i = find(count==0);

if flag == 0
	y = sqrt(sum(x.*x,dim)./max(count-1,1));
else
	y = sqrt(sum(x.*x,dim)./max(count,1));
end
y(i) = i + NaN;
function y = nanvar(x,dim,flag)
% FORMAT: Y = NANVAR(X,DIM,FLAG)
% 
%    Variance ignoring NaNs
%
%    This function enhances the functionality of NANVAR as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANVAR(X,DIM) calculates the standard deviation along any dimension of
%    the N-D array X ignoring NaNs.  
%
%    NANVAR(X,DIM,0) normalizes by (N-1) where N is SIZE(X,DIM).  This make
%    NANVAR(X,DIM).^2 the best unbiased estimate of the variance if X is
%    a sample of a normal distribution. If omitted FLAG is set to zero.
%    
%    NANVAR(X,DIM,1) normalizes by N and produces second moment of the 
%    sample about the mean.
%
%    If DIM is omitted NANVAR calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANMEDIAN, NANMIN, NANMAX, 
%    NANSTD, and NANSUM which are all part of the NaN-suite.
%
%    See also STD

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2008/05/02 21:46:17 $

if isempty(x)
	y = NaN;
	return
end

if nargin < 3
	flag = 0;
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1; 
	end	  
end


% Find NaNs in x and nanmean(x)
nans = isnan(x);
avg = nanmean(x,dim);

% create array indicating number of element 
% of x in dimension DIM (needed for subtraction of mean)
tile = ones(1,max(ndims(x),dim));
tile(dim) = size(x,dim);

% remove mean
x = x - repmat(avg,tile);

count = size(x,dim) - sum(nans,dim);

% Replace NaNs with zeros.
x(isnan(x)) = 0; 


% Protect against a  all NaNs in one dimension
i = find(count==0);

if flag == 0
	y = sum(x.*x,dim)./max(count-1,1);
else
	y = sum(x.*x,dim)./max(count,1);
end
y(i) = i + NaN;
function y = nansem(x,dim)
% FORMAT: Y = NANSEM(X,DIM)
% 
%    Standard error of the mean ignoring NaNs
%
%    NANSTD(X,DIM) calculates the standard error of the mean along any
%    dimension of the N-D array X ignoring NaNs.  
%
%    If DIM is omitted NANSTD calculates the standard deviation along first
%    non-singleton dimension of X.
%
%    Similar functions exist: NANMEAN, NANSTD, NANMEDIAN, NANMIN, NANMAX, and
%    NANSUM which are all part of the NaN-suite.

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/22 09:02:27 $

if isempty(x)
	y = NaN;
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1; 
	end	  
end


% Find NaNs in x and nanmean(x)
nans = isnan(x);

count = size(x,dim) - sum(nans,dim);


% Protect against a  all NaNs in one dimension
i = find(count==0);
count(i) = 1;

y = nanstd(x,dim)./sqrt(count);

y(i) = i + NaN;
function y = nansum(x,dim)
% FORMAT: Y = NANSUM(X,DIM)
% 
%    Sum of values ignoring NaNs
%
%    This function enhances the functionality of NANSUM as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).  
%
%    NANSUM(X,DIM) calculates the mean along any dimension of the N-D array
%    X ignoring NaNs.  If DIM is omitted NANSUM averages along the first
%    non-singleton dimension of X.
%
%    Similar replacements exist for NANMEAN, NANSTD, NANMEDIAN, NANMIN, and
%    NANMAX which are all part of the NaN-suite.
%
%    See also SUM

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.2 $ $Date: 2005/06/13 12:14:38 $

if isempty(x)
	y = [];
	return
end

if nargin < 2
	dim = min(find(size(x)~=1));
	if isempty(dim)
		dim = 1;
	end
end

% Replace NaNs with zeros.
nans = isnan(x);
x(isnan(x)) = 0; 

% Protect against all NaNs in one dimension
count = size(x,dim) - sum(nans,dim);
i = find(count==0);

y = sum(x,dim);
y(i) = NaN;
function [y,idx] = nanmin(a,dim,b)
% FORMAT: [Y,IDX] = NANMIN(A,DIM,[B])
% 
%    Minimum ignoring NaNs
%
%    This function enhances the functionality of NANMIN as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).
%
%    If fact NANMIN simply rearranges the input arguments to MIN because
%    MIN already ignores NaNs.
%
%    NANMIN(A,DIM) calculates the minimum of A along the dimension DIM of
%    the N-D array X. If DIM is omitted NANMIN calculates the minimum along
%    the first non-singleton dimension of X.
%
%    NANMIN(A,[],B) returns the minimum of the N-D arrays A and B.  A and
%    B must be of the same size.
%
%    Comparing two matrices in a particular dimension is not supported,
%    e.g. NANMIN(A,2,B) is invalid.
%    
%    [Y,IDX] = NANMIN(X,DIM) returns the index to the minimum in IDX.
%    
%    Similar replacements exist for NANMAX, NANMEAN, NANSTD, NANMEDIAN and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MIN

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:14 $

if nargin < 1
	error('Requires at least one input argument')
end

if nargin == 1
	if nargout > 1
		[y,idx] = min(a);
	else
		y = min(a);
	end
elseif nargin == 2
	if nargout > 1
		[y,idx] = min(a,[],dim);
	else
		y = min(a,[],dim);
	end
elseif nargin == 3
	if ~isempty(dim)
		error('Comparing two matrices along a particular dimension is not supported')
	else
		if nargout > 1
			[y,idx] = min(a,b);
		else
			y = min(a,b);
		end
	end
elseif nargin > 3
	error('Too many input arguments.')
end
function [y,idx] = nanmax(a,dim,b)
% FORMAT: [Y,IDX] = NANMAX(A,DIM,[B])
% 
%    Maximum ignoring NaNs
%
%    This function enhances the functionality of NANMAX as distributed in
%    the MATLAB Statistics Toolbox and is meant as a replacement (hence the
%    identical name).
%
%    If fact NANMAX simply rearranges the input arguments to MAX because
%    MAX already ignores NaNs.
%
%    NANMAX(A,DIM) calculates the maximum of A along the dimension DIM of
%    the N-D array X. If DIM is omitted NANMAX calculates the maximum along
%    the first non-singleton dimension of X.
%
%    NANMAX(A,[],B) returns the minimum of the N-D arrays A and B.  A and
%    B must be of the same size.
%
%    Comparing two matrices in a particular dimension is not supported,
%    e.g. NANMAX(A,2,B) is invalid.
%    
%    [Y,IDX] = NANMAX(X,DIM) returns the index to the maximum in IDX.
%    
%    Similar replacements exist for NANMIN, NANMEAN, NANSTD, NANMEDIAN and
%    NANSUM which are all part of the NaN-suite.
%
%    See also MAX

% -------------------------------------------------------------------------
%    author:      Jan Gl�scher
%    affiliation: Neuroimage Nord, University of Hamburg, Germany
%    email:       glaescher@uke.uni-hamburg.de
%    
%    $Revision: 1.1 $ $Date: 2004/07/15 22:42:11 $

if nargin < 1
	error('Requires at least one input argument')
end

if nargin == 1
	if nargout > 1
		[y,idx] = max(a);
	else
		y = max(a);
	end
elseif nargin == 2
	if nargout > 1
		[y,idx] = max(a,[],dim);
	else
		y = max(a,[],dim);
	end
elseif nargin == 3
	if ~isempty(dim)
		error('Comparing two matrices along a particular dimension is not supported')
	else
		if nargout > 1
			[y,idx] = max(a,b);
		else
			y = max(a,b);
		end
	end
elseif nargin > 3
	error('Too many input arguments.')
end




    