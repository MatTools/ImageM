classdef PlanarImageViewer < handle
%PLANARIMAGEVIEWER  A viewer for planar images
%
%   VIEWER = PlanarImageViewer(GUI, DOC)
%   Creates a VIEWER for an ImageM document.
%   GUI: the instance of ImagemGUI that manages all frames
%   DOC: the instance of ImagemDoc that contains the data to display.
%
%   Example
%     app = imagem.app.ImagemApp;
%     gui = imagem.gui.ImagemGUI(app);
%     img = Image.read('cameraman.tif');
%     doc = imagem.app.ImagemDoc(image);
%     addDocument(app, doc);
%     viewer = imagem.gui.PlanarImageViewer(this, doc);
%
%   See also
%     imagem.gui.ImagemGUI, imagem.app.ImagemDoc

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2011-03-10,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.


properties
    % reference to the main GUI
    gui;
   
    % list of handles to the various gui items
    handles;
    
    % the image document
    doc;
    
    % a row vector of two values indicating minimal and maximal displayable
    % values for grayscale and intensity images.
    displayRange;
    
    % specify how to change the zoom when figure is resized. Can be one of:
    % 'adjust'  -> find best zoom (default)
    % 'fixed'   -> keep previous zoom factor
    zoomMode = 'adjust';
    
    % the set of mouse listeners, stored as a cell array 
    mouseListeners = [];
    
    % the currently selected tool
    currentTool = [];
    
    % a selected shape
    selection = [];
end

methods
    function this = PlanarImageViewer(gui, doc)
        this.gui = gui;
        this.doc = doc;

        % computes a new handle index large enough not to collide with
        % common figure handles
        while true
            newFigHandle = 23000 + randi(10000);
            if ~ishandle(newFigHandle)
                break;
            end
        end

        % create the figure that will contains the display
        fig = figure(newFigHandle);
        set(fig, ...
            'MenuBar', 'none', ...
            'NumberTitle', 'off', ...
            'NextPlot', 'new', ...
            'Name', 'ImageM Main Figure', ...
            'Visible', 'Off', ...
            'CloseRequestFcn', @this.close);
        this.handles.figure = fig;
        
        % create main figure menu
        createFigureMenu(gui, fig, this);
        
        % creates the layout
        setupLayout(fig);
        
        updateDisplay(this);
        updateTitle(this);
        
        % adjust zoom to view the full image
        api = iptgetapi(this.handles.scrollPanel);
        mag = api.findFitMag();
        api.setMagnification(mag);

        % setup listeners associated to the figure
        if ~isempty(doc) && ~isempty(doc.image)
            set(fig, 'WindowButtonDownFcn',     @this.processMouseButtonPressed);
            set(fig, 'WindowButtonUpFcn',       @this.processMouseButtonReleased);
            set(fig, 'WindowButtonMotionFcn',   @this.processMouseMoved);

            % setup mouse listener for display of mouse coordinates
            tool = imagem.gui.tools.ShowCursorPositionTool(this, 'showMousePosition');
            addMouseListener(this, tool);
            
            % setup key listener
            set(fig, 'KeyPressFcn',     @this.onKeyPressed);
            set(fig, 'KeyReleaseFcn',   @this.onKeyReleased);
        end
        
        set(fig, 'UserData', this);
        set(fig, 'Visible', 'On');
        
        
        function setupLayout(hf)
            
            % vertical layout: image display and status bar
            mainPanel = uix.VBox('Parent', hf, ...
                'Units', 'normalized', ...
                'Position', [0 0 1 1]);
            
            % panel for image display
            displayPanel = uix.VBox('Parent', mainPanel);
            
            % scrollable panel for image display
            scrollPanel = uipanel('Parent', displayPanel, ...
                'resizeFcn', @this.onScrollPanelResized);
          
            % creates an axis that fills the available space
            ax = axes('Parent', scrollPanel, ...
                'Units', 'Normalized', ...
                'NextPlot', 'add', ...
                'Position', [0 0 1 1]);
            
            % intialize image display with default image. 
            hIm = imshow(ones(10, 10), 'parent', ax);
            this.handles.scrollPanel = imscrollpanel(scrollPanel, hIm);

            % keep widgets handles
            this.handles.imageAxis = ax;
            this.handles.image = hIm;

            % in case of empty doc, hides the axis
            if isempty(this.doc) || isempty(this.doc.image)
                set(ax, 'Visible', 'off');
                set(hIm, 'Visible', 'off');
            end

            % info panel for cursor position and value
            this.handles.infoPanel = uicontrol(...
                'Parent', mainPanel, ...
                'Style', 'text', ...
                'String', ' x=    y=     I=', ...
                'HorizontalAlignment', 'left');
                        
            % set up relative sizes of layouts
            mainPanel.Heights = [-1 20];

            % once each panel has been resized, setup image magnification
            api = iptgetapi(this.handles.scrollPanel);
            mag = api.findFitMag();
            api.setMagnification(mag);
        end
      
    end
end

methods
    
    function updateDisplay(this)
        % Refresh image display of the current slice

        % basic check up to avoid problems when display is already closed
        if ~ishandle(this.handles.scrollPanel)
            return;
        end
        
        % check up doc validity
        if isempty(this.doc) || isempty(this.doc.image)
            return;
        end
        
        % current image is either the document image, or the preview image
        % if there is one
        img = this.doc.image;
        if ~isempty(this.doc.previewImage)
            img = this.doc.previewImage;
        end
        
        % compute display data
        % TODO: label image need to use LUT and BGCOLOR
        cdata = imagem.gui.ImageUtils.computeDisplayImage(img);
       
        % changes current display data
        api = iptgetapi(this.handles.scrollPanel);
%         loc = api.getVisibleLocation();
        api.replaceImage(cdata, 'PreserveView', true);
        
        % extract calibration data
        spacing = img.spacing;
        origin  = img.origin;
        
        % set up spatial calibration
        dim     = size(img);
        xdata   = ([0 dim(1)-1] * spacing(1) + origin(1));
        ydata   = ([0 dim(2)-1] * spacing(2) + origin(2));
        
        set(this.handles.image, 'XData', xdata);
        set(this.handles.image, 'YData', ydata);
        
        % setup axis extent from image extent
        extent = physicalExtent(img);
        set(this.handles.imageAxis, 'XLim', extent(1:2));
        set(this.handles.imageAxis, 'YLim', extent(3:4));
%         api.setVisibleLocation(loc);
        
        % eventually adjust displayrange
        if isGrayscaleImage(img) || isIntensityImage(img) || isVectorImage(img)
            % get min and max display values, or recompute them
            if isempty(this.displayRange)
                [mini, maxi] = imagem.gui.ImageUtils.computeDisplayRange(img);
            else
                mini = this.displayRange(1);
                maxi = this.displayRange(2);
            end
            
            set(this.handles.imageAxis, 'CLim', [mini maxi]);
        end
        
        % set up lookup table (if not empty)
        if ~isColorImage(img) && ~isempty(this.doc.lut)
            colormap(this.handles.imageAxis, this.doc.lut);
        end
        
        % remove all axis children that are not image
        children = get(this.handles.imageAxis, 'Children');
        for i = 1:length(children)
            child = children(i);
            if ~strcmpi(get(child, 'type'), 'image')
                delete(child);
            end
        end
        
        % display each shape stored in document
        drawShapes(this);
        
%         % adjust zoom to view the full image
%         api = iptgetapi(this.handles.scrollPanel);
%         mag = api.findFitMag();
%         api.setMagnification(mag);
    end
    

    function updateTitle(this)
        % set up title of the figure, containing name of figure and current zoom
        
        % small checkup, because function can be called before figure was
        % initialised
        if ~isfield(this.handles, 'figure')
            return;
        end
        
        if isempty(this.doc) || isempty(this.doc.image)
            return;
        end
        
        % setup name
        if isempty(this.doc.image.name)
            imgName = 'Unknown Image';
        else
            imgName = this.doc.image.name;
        end
    
        % determine the type to display:
        % * data type for intensity / grayscale image
        % * type of image otherwise
        switch this.doc.image.type
            case 'grayscale'
                type = class(this.doc.image.data);
            case 'color'
                type = 'color';
            otherwise
                type = this.doc.image.type;
        end
        
        % compute image zoom
        api = iptgetapi(this.handles.scrollPanel);
        zoom = api.getMagnification();
        
        % compute new title string 
        titlePattern = 'ImageM - %s [%d x %d %s] - %g:%g';
        titleString = sprintf(titlePattern, imgName, ...
            size(this.doc.image), type, max(1, zoom), max(1, 1/zoom));

        % display new title
        set(this.handles.figure, 'Name', titleString);
    end
    
    function copySettings(this, that)
        % copy display settings from another viewer
        this.displayRange = that.displayRange;
        this.zoomMode = that.zoomMode;
    end
end

%% Shapes and Annotation management
methods
        
    function drawShapes(this)
        shapes = this.doc.shapes;
        for i = 1:length(shapes)
            drawShape(this, shapes{i});
        end
    end
    
    function h = drawShape(this, shape)
        
        % extract current axis
        ax = this.handles.imageAxis;
%         axes(this.handles.imageAxis);
        
        switch lower(shape.type)
            case 'polygon'
                h = drawPolygon(ax, shape.data, shape.style{:});
            case 'pointset'
                h = drawPoint(ax, shape.data, shape.style{:});
            case 'box'
                h = drawBox(ax, shape.data, shape.style{:});
            case 'ellipse'
                h = drawEllipse(ax, shape.data, shape.style{:});
        end
    end

end

%% Zoom Management
methods
    function zoom = getZoom(this)
        api = iptgetapi(this.handles.scrollPanel);
        zoom = api.getMagnification();
    end
    
    function setZoom(this, newZoom)
        api = iptgetapi(this.handles.scrollPanel);
        api.setMagnification(newZoom);
    end
    
    function zoom = findBestZoom(this)
        api = iptgetapi(this.handles.scrollPanel);
        zoom = api.findFitMag();
    end
    
    function mode = getZoomMode(this)
        mode = this.zoomMode;
    end
    
    function setZoomMode(this, mode)
        switch lower(mode)
            case 'adjust'
                this.zoomMode = 'adjust';
            case 'fixed'
                this.zoomMode = 'fixed';
            otherwise
                error(['Unrecognized zoom mode option: ' mode]);
        end
    end
end


%% Mouse listeners management
methods
    function addMouseListener(this, listener)
        % Add a mouse listener to this viewer
        this.mouseListeners = [this.mouseListeners {listener}];
    end
    
    function removeMouseListener(this, listener)
        % Remove a mouse listener from this viewer
        
        % find which listeners are the same as the given one
        inds = false(size(this.mouseListeners));
        for i = 1:numel(this.mouseListeners)
            if this.mouseListeners{i} == listener
                inds(i) = true;
            end
        end
        
        % remove first existing listener
        inds = find(inds);
        if ~isempty(inds)
            this.mouseListeners(inds(1)) = [];
        end
    end
    
    function processMouseButtonPressed(this, hObject, eventdata)
        % propagates mouse event to all listeners
        for i = 1:length(this.mouseListeners)
            onMouseButtonPressed(this.mouseListeners{i}, hObject, eventdata);
        end
    end
    
    function processMouseButtonReleased(this, hObject, eventdata)
        % propagates mouse event to all listeners
        for i = 1:length(this.mouseListeners)
            onMouseButtonReleased(this.mouseListeners{i}, hObject, eventdata);
        end
    end
    
    function processMouseMoved(this, hObject, eventdata)
        % propagates mouse event to all listeners
        for i = 1:length(this.mouseListeners)
            onMouseMoved(this.mouseListeners{i}, hObject, eventdata);
        end
    end
end

%% Mouse listeners management
methods
    function onKeyPressed(this, hObject, eventdata) %#ok<INUSL>
%         disp(['key pressed: ' eventdata.Character]);
        
        key = eventdata.Character;
        switch key
        case '+'
            zoom = getZoom(this);
            setZoom(this, zoom * sqrt(2));
            updateTitle(this);
            
        case '-'
            zoom = getZoom(this);
            setZoom(this, zoom / sqrt(2));
            updateTitle(this);
            
        case '='
            setZoom(this, 1);
            updateTitle(this);
            
        end
    end
    
    function onKeyReleased(this, hObject, eventdata) %#ok<INUSD>
%         disp(['key relased: ' eventdata.Character]);
    end
    
end

%% Figure management
methods
    function close(this, varargin)
%         disp('Close image viewer');
        if ~isempty(this.doc)
            try
                removeView(this.doc, this);
            catch ME %#ok<NASGU>
                warning('PlanarImageViewer:close', ...
                    'Current view is not referenced in document...');
            end
        end
        delete(this.handles.figure);
    end
    
    function onScrollPanelResized(this, varargin)
        % function called when the Scroll panel has been resized
        
       if strcmp(this.zoomMode, 'adjust')
            if ~isfield(this.handles, 'scrollPanel')
                return;
            end
            scroll = this.handles.scrollPanel;
            api = iptgetapi(scroll);
            mag = api.findFitMag();
            api.setMagnification(mag);
            updateTitle(this);
        end
    end
    
end

end