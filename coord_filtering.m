%% Block to create dataf structure containing names of dat files in name field

clear;
data = dir;
j=1;
badfiles=[];
badfiles_counter = 0;
error_val=cell(1,6);
start=1;

for i = 1:size(data,1)
    if any(strfind(data(i).name,'.dat')) == 1
        dataf(j).name = data(i).name;
        j=j+1;
    end
end

for file_counter = start:size(dataf,2)
%% Clearing headers   
    cellOrig = readcell(dataf(file_counter).name);
    cell0 = cellOrig;
    array = cell2array_clear(cell0);
    if mean(array(:,1))> 20
        disp('Large numbers')
        disp(dataf(file_counter).name)
        badfiles_counter=badfiles_counter+1;
        badfiles{badfiles_counter,1}=dataf(file_counter).name;
        badfiles{badfiles_counter,2}='Large numbers';
        continue
    end
    array = remove_num_header(array);
    L = size(array,1);
%% Find TE
    x_right = -Inf;
    for j = 1:L                    
            if array(j,1) > x_right
                x_right = array(j,1);
                y_right = array(j,2);
                pos_1 = j;
            end
    end
    
    x_right1 = -Inf;
    for j = 1:L                    
            if array(j,1) > x_right1 && j~=pos_1 
                x_right1 = array(j,1);
                y_right1 = array(j,2);
                pos_2 = j;
            end
    end
        
    TE1 = ismember(array(:,1),x_right);
    TE2 = ismember(array(:,1),x_right1);
    TE = TE1+TE2;
    TErows = find(TE==1);

    te = [array(pos_1,:); array(pos_2,:)];

    
    if abs(te(1,1)-te(2,1))<0.0008
        ROTpoint = [mean(te(:,1)), mean(te(:,2))];
    else
        ROTpoint = [te(1,:)];
    end
%% Block to move and rotate so there always LE at [0 0] and TE [x 0] or [x y] [x -y]
    dist=pdist2(array, ROTpoint, 'euclidean');
    LE_position = find(dist==max(dist));

    LE = [array(LE_position(1),1) array(LE_position(1),2)];

    rel_vec = ROTpoint - LE;
    array = array - LE;
    angle =  atan2(rel_vec(2), rel_vec(1));
    rot_angle = -angle;
    R_M = [ cos(rot_angle)      -sin(rot_angle)
            sin(rot_angle)       cos(rot_angle) ];
    array_2=[];
    for i=1:length(array)
        array_2(i,:) =( R_M*(array(i,:))')';
    end
    array=array_2;  
%% Block to scale so there always is TE at [1 *]
    x_right = -Inf;
    for j = 1:L                    
            if array(j,1) > x_right
                x_right = array(j,1);
                y_right = array(j,2);
            end
    end
    TE = ismember(array(:,1),x_right);
    TErows = find(TE==1);
    thick = 0;

     if length(TErows) == 2 && array(TErows(1),2)~=array(TErows(2),2) %Detect thick TE
          thick = 1;
     end
    
    if array(TErows,1)~=1 %checks if there at least one TE with [1 *], if not, scales
        maxx = max(array(:,1)); %finds max X value
        for j = 1:size(array,1)
            array(j,:) = array(j,:)/maxx; %scales all points so there is [1 *]
        end
        TE = ismember(array(:,1),x_right); %saves corrected TE for further use
        TErows = find(TE==1);
    end   
     array_3=array;

    LE = ismember(array,[0 0],'rows'); %finds LE with coord [0 0]
    LErows = find(LE==1);
%% Block to rearrange to correct format (TE->upperside->LE->lowerside->TE)
    sizea = size(array,1);
    sizeTE = size(TErows,1);
    sizeLE = size(LErows,1);
    
    top = ismember(array(:,2),max(array,2));
    toprow = find(top==1);
    bot = ismember(array(:,2),min(array,2));
    botrow = find(bot==1); 
    
    switch sizeLE
        case 1
            if array(1,2) > array (5,2) %checks if clockwise
                array = flip(array);
                x=1
            end
        case 2
            switch sizeTE
                case 1
                    if array(1,2) < array (5,2)
                        array = flip(array);
                        x=2
                    end
                    array=cat(1,array(TErows:end,:),array(2:TErows,:));
                case 2
                    if TErows(1,1) == 1
                        if array(1,2) > array (5,2)
                            array = flip(array);
                            x=3
                        end
                            array=cat(1,array(1:LErows(2),:),flip(array((LErows(2)+1):(end-1),:)));
                    elseif LErows(1,1) == 1
                        x=4
                        if array(1,2) < array (5,2)
                            array = flip(array);
                            x=5
                        end
                        array=cat(1,flip(array(LErows(2):end,:)),array(2:(LErows(2)-1),:));
                        x=6
                    else
                        disp('Error in rebuilbing in')
                        disp(dataf(file_counter).name)
                        badfiles_counter=badfiles_counter+1;
                        badfiles{badfiles_counter,1}=dataf(file_counter).name;
                        badfiles{badfiles_counter,2}='Error in rebuilbing';
                        continue
                    end
            end     
            
    end
    array_4=array;
    save(char(['coord_' dataf(file_counter).name]),'array','-ascii');
    movefile coord* coords;
     movefile(dataf(file_counter).name,'processed/');
end  

%% Functions
function matrix = cell2array_clear(cell0)
   
sizec = size(cell0);
cell_t = cell2table(cell0);
cell_miss = ismissing(cell_t);
cell_new=cell([sizec(1) 1]);
c=1;
for j=1:sizec(2)
   if isnumeric(cell0{floor(sizec(1)/3),j})
       cell_new(:,c) = cell0(:,j); 
       c=c+1;
   end
end

cell0 = cell_new;

for h=1:2
    k=1;
    while k<5
            for j=1:length(cell0(k,:))
                if not(isnumeric(cell0{k,j}))
                    cell0(k,:)=[];
                else
                    k=k+1;
                end
            end
    end
 
    cell0 = flip(cell0);
end  

    cell2=cell0(~cellfun('isempty',cell0));
    array=table2array(cell2table(cell2));

    if size(array,2) == 1
        matrix=[array(1:length(array)/2,1),array(length(array)/2+1:length(array),1)];
    else
        matrix = array;
    end
end

function filtered_array = remove_num_header(array)
    while array(1,1) > 1.5 || array(1,1) < -0.5 || array(1,2) > 0.5 || array(1,2) < -0.5
            array(1,:)=[];
    end
    while array(length(array),1) > 1.5 || array(length(array),1) < -0.5 || array(length(array),2) > 0.5 || array(length(array),2) < -0.5
            array(length(array),:)=[];
    end
    filtered_array = array;
end