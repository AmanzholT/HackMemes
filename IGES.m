data = dir('AirfoilParametersDB_04022020.txt');
j=1;
start=1
fname = 'AirfoilParametersDB_04022020.txt';
%fid=fopen(fname);
l=1;
v=[];
te=[];
w=ones(1,12);
t= readtable(fname,'Delimiter','	', 'ReadVariableNames', true);
t_var = t(:,3:21);
t_mat = t_var.Variables;
t_names = t.name(:);
 for i=1:height(t)
    if t.symmetric
        s=1;
        v=t_mat(i,1:7);
        te = t_mat(i,8:9);
    else
        s=0;
        v=t_mat(i,1:15);
        te = t_mat(i,16:17);
    end
    
    [ crv, crv_u, crv_l ] = airfoil_pmodel_ext1( v, l, s, w, te);
    outName = string(t_names(i))+'.igs';
    nrb2iges(crv, outName);
    movefile(outName,'igs/');
end
% for i = 1:size(data,1)
%     if any(strfind(data(i).name,'.dat')) == 1
%         dataf(j).name = data(i).name;
%         j=j+1;
%     end
% end
% 
% for file_counter = start:1%size(dataf,2)
%     [v, te, s] = estimate_parameters(dataf(file_counter).name);
%     [crv, crv_u, crv_l] = airfoil_pmodel_ext1( v, 1, s);
%     [obj_val, max_val, min_val] = objective_modified(dataf(file_counter).name, crv);
%     if max_val > 0.0008
%         x=1
%     end
% end
