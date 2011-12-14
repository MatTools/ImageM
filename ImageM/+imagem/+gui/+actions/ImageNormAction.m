classdef ImageNormAction < imagem.gui.ImagemAction
%IMAGENORMACTION Compute norm of current image
%
%   output = ImageNormAction(input)
%
%   Example
%   ImageNormAction
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2011-03-10,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.

methods
    function this = ImageNormAction(parent, varargin)
        % calls the parent constructor
        this = this@imagem.gui.ImagemAction(parent, 'imageNorm');
    end
end

methods
    function actionPerformed(this, src, event) %#ok<INUSD>
        disp('Compute image norm');
        
        % get handle to parent figure, and current doc
        viewer = this.parent;
        doc = viewer.doc;
        
        % apply 'norm' operation
        img2 = norm(doc.image);
        
        % add image to application, and create new display
        addImageDocument(viewer.gui, img2);
    end
end

methods
    function b = isActivable(this)
        doc = this.parent.doc;
        b = ~isempty(doc.image) && ~isScalarImage(doc.image);
    end
end

end