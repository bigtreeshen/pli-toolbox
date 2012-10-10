function plidemo_linsvm(n, solver)
%PLIDEMO_LINSVM Demonstrates the use of linear SVM
%
%   PLIDEMO_LINSVM();
%   PLIDEMO_LINSVM(n);
%   PLIDEMO_LINSVM(n, solver);
%
%       Here, n is the number of samples of each class.
%       The default value of n is 500;
%
%       solver is either 'ip', 'gurobi', or 'pegasos'.       
%

%% arguments

if nargin < 1
    n = 500;
end

if nargin < 2
    solver = 'ip';
end

%% Data generation

t = pi / 3;
R = [cos(t) -sin(t); sin(t) cos(t)];
Z = R * diag([4, 1]) * randn(2, 2 * n);

Xp = bsxfun(@plus, Z(:, 1:n), [0 0]');
Xn = bsxfun(@plus, Z(:, n+1:2*n), [10 0]');

X = [Xp, Xn];
y = [ones(1, n), -ones(1, n)];

%% Solve SVM

switch solver    

    case {'ip', 'gurobi'}
        c = 10;
        
        opts = [];        
        if strcmp(solver, 'ip')
            opts = optimset('Display', 'iter');
        elseif strcmp(solver, 'gurobi')
            opts.outputflag = 1;
        end
        
        tic;
        [w, w0, ~, objv] = pli_linsvm(X, y, c, solver, opts);
        solve_time = toc;
                
    case 'pegasos'   
        lambda = 1e-3;
        T = 200 / lambda;
        aug = 10;
        
        tic;
        [w, w0] = pli_pegasos(X, y, lambda, T, aug);
        solve_time = toc;   
        
        objv = [];
end

% show solution

fprintf('Solve time = %.4f sec\n', solve_time);

disp('Solutions');
disp('=============');
display(w);
display(w0);
if ~isempty(objv)
    display(objv);
end



%% Visualization

figure;
plot(Xp(1,:), Xp(2,:), 'g.');
hold on;
plot(Xn(1,:), Xn(2,:), 'm.');

axis equal;

px = X(1,:);
py = X(2,:);
rgn = [min(px), max(px), min(py), max(py)];

drawline(rgn, w, w0, 'Color', 'b');
drawline(rgn, w, w0 - 1.0, 'Color', [0 0.5 0]);
drawline(rgn, w, w0 + 1.0, 'Color', [0.5 0 0]);

r = y .* (w' * X + w0);
sv = find(r < 1 + 1.0e-6);
if ~isempty(sv)
    hold on;
    plot(X(1, sv), X(2, sv), 'ro', 'MarkerSize', 10);
end


function drawline(rgn, w, w0, varargin)
% Draws a line on current axis
%
%   rgn = [xmin, xmax, ymin, ymax];
%
%   Draw line: w(1) * x + w(2) * y + w0 = 0;

xmin = rgn(1);
xmax = rgn(2);
ymin = rgn(3);
ymax = rgn(4);

w1 = w(1);
w2 = w(2);

if abs(w1) < abs(w2)
    
    x0 = xmin - 0.1 * (xmax - xmin);
    x1 = xmax + 0.1 * (xmax - xmin);
    
    y0 = -(w1 * x0 + w0) / w2;
    y1 = -(w1 * x1 + w0) / w2;
    
else
    y0 = ymin - 0.1 * (ymax - ymin);
    y1 = ymax + 0.1 * (ymax - ymin);
    
    x0 = -(w2 * y0 + w0) / w1;
    x1 = -(w2 * y1 + w0) / w1;
    
end

line([x0, x1], [y0, y1], varargin{:});


