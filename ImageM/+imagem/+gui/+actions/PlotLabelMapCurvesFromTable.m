classdef PlotLabelMapCurvesFromTable < imagem.gui.actions.LabelImageAction
% One-line description here, please.
%
%   Class PlotLabelMapCurvesFromTable
%
%   Example
%   PlotLabelMapCurvesFromTable
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2019-09-18,    using Matlab 9.6.0.1072779 (R2019a)
% Copyright 2019 INRA - BIA-BIBS.


%% Properties
properties
end % end properties


%% Constructor
methods
    function obj = PlotLabelMapCurvesFromTable(viewer)
        % Constructor for PlotLabelMapCurvesFromTable class
        
        % calls the parent constructor
        obj = obj@imagem.gui.actions.LabelImageAction(viewer, 'plotLabelMapCurvesFromTable');

    end

end % end constructors


%% Methods
methods
    function actionPerformed(obj, src, event) %#ok<INUSD>
        disp('plot label map curves from data table');
        
        [fileName, pathName] = uigetfile( ...
            {'*.txt;*.csv;*.div', ...
            'All Data Table Files (*.txt, *.csv, *.div)'; ...
            '*.txt',                    'TEXT Files (*.txt)'; ...
            '*.csv',                    'CSV Files (*.csv)'; ...
            '*.div',                    'DIV Files (*.div)'; ...
            '*.*',                      'All Files (*.*)'}, ...
            'Choose a data table:');
        
        if isequal(fileName,0) || isequal(pathName,0)
            return;
        end
        
        % read the selected file
        tablePath = fullfile(pathName, fileName);
        tab = Table.read(tablePath);
        
        viewer = obj.Viewer;
        tool = imagem.gui.tools.PlotClickedLabelCurve(obj.Viewer, tab);
        
        viewer.CurrentTool = tool;
    end
end % end methods

end % end classdef

