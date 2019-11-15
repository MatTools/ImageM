classdef ConvertImage3DToVectorImage < imagem.actions.Image3DAction
%CONVERTIMAGE3DTOVECTORIMAGE  One-line description here, please.
%
%   Class ConvertImage3DToVectorImage
%
%   Example
%   ConvertImage3DToVectorImage
%
%   See also
%

% ------
% Author: David Legland
% e-mail: david.legland@inra.fr
% Created: 2019-11-15,    using Matlab 9.7.0.1190202 (R2019b)
% Copyright 2019 INRA - BIA-BIBS.


%% Properties
properties
end % end properties


%% Constructor
methods
    function obj = ConvertImage3DToVectorImage(varargin)
    % Constructor for ConvertImage3DToVectorImage class

    end

end % end constructors


%% Methods
methods
    function run(obj, frame) %#ok<INUSL,INUSD>
        
        % get handle to current doc
        doc = currentDoc(frame);
        
        % apply the conversion operation
        res = Image('Data', doc.Image.Data, 'vector', true);
        
        % create a new doc
        newDoc = addImageDocument(frame, res);
        
        % add history
        string = sprintf('%s = Image(''Data'', %s.Data, ''vector'', true);\n', ...
            newDoc.Tag, doc.Tag);
        addToHistory(frame, string);
    end
    
end % end methods

end % end classdef

