classdef ChangeImageLutAction < imagem.gui.ImagemAction
%CHANGEIMAGELUTACTION  One-line description here, please.
%
%   output = ChangeImageLutAction(input)
%
%   Example
%   ChangeImageLutAction
%
%   See also
%
%
% ------
% Author: David Legland
% e-mail: david.legland@grignon.inra.fr
% Created: 2011-12-11,    using Matlab 7.9.0.529 (R2009b)
% Copyright 2011 INRA - Cepia Software Platform.

properties
    lut = [];
    lutName;
end

methods
    function this = ChangeImageLutAction(parent, lutName, lutValues)
        % calls the parent constructor
        this = this@imagem.gui.ImagemAction(parent, 'changeImageLut');
        this.lutName = lutName;
        if nargin > 2
            this.lut = lutValues;
        end
    end
end

methods
    function actionPerformed(this, src, event) %#ok<INUSD>
        disp(['Change Image LUT to ' this.lutName]);
        
        % get handle to parent figure, and current doc
        viewer = this.parent;
        doc = viewer.doc;

        if strcmp(this.lutName, 'none')
            doc.lut = [];
        else
            
            if isempty(this.lut)
                this.lut = computeLutFromName(this);
                doc.lut = this.lut;
            end
        end
        
        doc.lutName = this.lutName;
        doc.modified = true;
        
        updateDisplay(this.parent);
    end
    
    function lut = computeLutFromName(this)
        name = this.lutName;
        nGrays = 256;
        if strcmp(name, 'inverted')
            lut = repmat((255:-1:0)', 1, 3) / 255;
            
        elseif strcmp(name, 'blue-gray-red')
            lut = gray(nGrays);
            lut(1,:) = [0 0 1];
            lut(end,:) = [1 0 0];
            
        elseif strcmp(name, 'colorcube')
            img = this.parent.doc.image;
            nLabels = round(max(img));
            map = colorcube(double(nLabels) + 2);
            lut = [0 0 0; map(sum(map==0, 2)~=3 & sum(map==1, 2)~=3, :)];
            
        elseif strcmp(name, 'red')
            lut = gray(nGrays);
            lut(:, 2:3) = 0;
            
        elseif strcmp(name, 'green')
            lut = gray(nGrays);
            lut(:, [1 3]) = 0;
            
        elseif strcmp(name, 'blue')
            lut = gray(nGrays);
            lut(:, 1:2) = 0;
            
        elseif strcmp(name, 'yellow')
            lut = gray(nGrays);
            lut(:, 3) = 0;
            
        elseif strcmp(name, 'cyan')
            lut = gray(nGrays);
            lut(:, 1) = 0;
            
        elseif strcmp(name, 'magenta')
            lut = gray(nGrays);
            lut(:, 2) = 0;
            
        else
            lut = feval(name, nGrays);
        end

    end
end

methods
    function b = isActivable(this)
        doc = this.parent.doc;
        b = ~isempty(doc.image) && ~isColorImage(doc.image);
    end
end

end