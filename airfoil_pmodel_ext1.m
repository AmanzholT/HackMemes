function [ crv, crv_u, crv_l ] = airfoil_pmodel_ext1( v, l, s, w, te)
% Simple airfoil parametric script modelling both profile sides
% Initial version 28.06.2017 K.V. Kostas (konstantinos.kostas@nu.edu.kz)
% 28.05.2018, Addition of a new leading edge angle parameter
% 09.06.2018, Added parameters dialog and adapted for the needs of NIS 2018 visit to NU SEng
% 11.06.2018, Modified construction of upper and lower aft parts
% 16.06.2018, Read parameters from file
% 02.12.2019, Conversion to MATLAB
% 23.08.2019, Extension of parametric model to include additional parameters controlling the LE and TE areas
% 06.09.2019, Extension of parametric model to include weights
% 17.09.2019, Extension of parametric model to include TE thickness for the upper and lower side (te(1)->upper, te(2)->lower)

% crv: resulting airfoil as a NURBS curve
% crv_u: suction side
% crl_l: pressure side
% v: design vector 
% l: chord length
% s: is airfoil symmetric (TRUE/FALSE)
% All parameters in [0,1]:
% 1. u_max: max upper side width              						(actual bounds [0.01*Length/5, Length/5])  
% 2. l_max: max lower side width              						(actual bounds [0.01*Length/5, Length/5])
% 3. x_u_max: longitudinal position of maximum upper side width     (actual bounds [0.1*Length, 0.7*Length])
% 4. x_l_max: longitudinal position of maximum lower side width		(actual bounds [0.1*Length, x_u_max])
% 5. angle_b_u: angle at trailing edge (upper side) 				(actual bounds [atn(z_max/(1-x_z_max)+pi/180, 89*pi/180] )
% 6. angle_b_l: angle at trailing edge (lower side) 				(actual bounds [-1, .95]*angle_b_u)
% 7. tip_u1: upper tip_bulb 0-> slender tip , 1->full tip (1st cp)	(actual bounds [0.05,1])
% 8. tip_u2: upper tip_bulb 0-> slender tip , 1->full tip (2nd cp)	(actual bounds [0.05,1])
% 9. tip_l1: lower tip_bulb: 0-> slender tip , 1->full tip (1st cp)	(actual bounds [0.05,1])
%10. tip_l2: lower tip_bulb: 0-> slender tip , 1->full tip (2nd cp)	(actual bounds [0.05,1])
%11. s_u1: shape of inflection point area (0 smooth, 1-> abrupt) p1	(actual bounds [0,0.9])
%12. s_u2: shape of inflection point area (0 smooth, 1-> abrupt) p2	(actual bounds [0,0.95])
%13. s_l1: shape of inflection point area (0 smooth, 1-> abrupt) p1 (actual bounds [0,0.9])
%14. s_l2: shape of inflection point area (0 smooth, 1-> abrupt) p2 (actual bounds [0,0.95])
%15. angle_l: angle at leading edge (w.r.t y-axis)				    (actual bounds [-20, +20]deg)

if nargin==1
    l = 1;
    s = false;
    w=ones(1,12);
	te=[0,0];
elseif nargin==2
    s = false;
    w=ones(1,12);
	te=[0,0];
elseif nargin==3
    w=ones(1,12);
	te=[0,0];
elseif nargin==4
    te=[0,0];
end
Length = l;

u_max = v(1) * (0.99 * Length/5 ) + 0.01 * Length/5 ;
x_u_max = v(2) * 0.7 * Length + 0.01 * Length;
angle_b_u = v(3) * 90 * pi / 180;
tip_u1 = v(4) * 0.95 + 0.05;
tip_u2 = v(5) * 0.95 + 0.05;
x_d1_min = x_u_max + (Length-x_u_max)*0.05;
s_u1 = x_d1_min + v(6)*0.9*(Length-x_d1_min);
x_d2_min = max(Length - (u_max-te(1)) / tan(angle_b_u),x_d1_min);
s_u2 = x_d2_min + v(7)*0.95*(Length-x_d2_min);
if ~s %not symmetric airfoil case
    l_max = v(8) * (0.99 * Length/5 ) + 0.01 * Length/5 ;
    x_l_max = v(9) * 0.7 * Length + 0.01 * Length;
    angle_b_l = -angle_b_u + 1.95 * v(10) * angle_b_u;
    tip_l1 = v(11) * 0.95 + 0.05;
    tip_l2 = v(12) * 0.95 + 0.05;
    x_d1_min = x_l_max + (Length-x_l_max)*0.05;
    s_l1 = x_d1_min + v(13)*0.9*(Length-x_d1_min);
    x_d2_min = max(Length - (l_max+te(2)) / tan(abs(angle_b_l)),x_d1_min);
    s_l2 = x_d2_min + v(14)*0.95*(Length-x_d2_min);
    angle_l = (v(15) * 40 - 20)*pi/180;
else
	angle_l = 0;
end
%Upper Side
point_a = [0, 0, 0, 1].*w(1);
point_b1 = [0, tip_u1 * u_max, 0, 1].*w(2);
point_b2 = [(1 - tip_u2) * x_u_max, u_max, 0, 1].*w(3);
point_c = [x_u_max, u_max, 0, 1].*w(4);
point_d1 = [s_u1, u_max, 0, 1].*w(5);
point_d2 = [s_u2, (Length-s_u2)*tan(angle_b_u)+te(1), 0, 1].*w(6);
point_e = [Length, te(1), 0, 1].*w(7);
%rotate control points around leading edge
point_b1 = [point_b1]*vecrotz(angle_l);
%point_b1 = point_b1(1:3);
%create upper side curve
upperSide = nrbmak([point_a', point_b1', point_b2', point_c', point_d1', point_d2', point_e'], [0,0, 0, 0, .5, .5, .5, 1, 1, 1, 1]);
%Lower Side
if s
    lowerSide = upperSide;
    lowerSide.coefs(2,:) = -lowerSide.coefs(2,:);
else
    point_b1 = [0, -tip_l1 * l_max, 0, 1].*w(8);
    point_b2 = [(1 - tip_l2) * x_l_max, -l_max, 0, 1].*w(9);
    point_c = [x_l_max, -l_max, 0, 1].*w(10);
    point_d1 = [s_l1, -l_max, 0, 1].*w(11);
    if angle_b_l > 0 
        x_d2_min = max(Length - (point_d2(2)-te(2)) / abs(angle_b_l),x_d1_min);
        s_l2 = x_d2_min + v(14)*0.95*(Length-x_d2_min);
    end
    point_d2 = [s_l2, (Length-s_l2)*tan(angle_b_l)+te(2), 0, 1].*w(12);
    %rotate control points around leading edge
    point_b1 = [point_b1]*vecrotz(angle_l);
    %construct lower side curve
    point_e = [Length, te(2), 0, 1].*w(7);
    lowerSide = nrbmak([point_a', point_b1', point_b2', point_c', point_d1', point_d2', point_e'], [0,0, 0, 0, .5, .5, .5, 1, 1, 1,1]);
end
%Construct a curve from both sides
crv = nrbmak([fliplr(upperSide.coefs),lowerSide.coefs(:,2:end)],[0,0, 0, 0, .25, .25, .25, .5, .5, .5, .75, .75, .75, 1, 1, 1,1]);
crv_l = lowerSide;
crv_u = upperSide;
	%create_airfoil = Array(Rhino.CurveLength(airfoil_crv), Array(airfoil_crv, lowerSide, upperSide), Rhino.CurveArea(airfoil_crv))
end

