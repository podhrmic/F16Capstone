function xd = F16sixDegreeFreedom_SC(x,u)
% Cam Osborn 2/28/2020
% An Adaptation of Stevens Fortran subroutine.
% F16sixDegreeFreedom Calculates the state derivative based on the 
% control vector and state vector.
% INPUTS:
%    u - Control Vector
%    x - State Vector
% OUTPUTS:
%    xd - State Derivative Vector
xd = [0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; ];
% Constants
  
    k1 = 0.0055;                    % Wing Area Constant
    k2 = 0.079;                     % Wingspan Constant
    k3 = 1.7965e-4;                 % Mass Scaling Factor
    
    
 % Data
   S     = 300*k1;                   % Wing Planform Area Multiplied by Scaling Factor
   B     = 2.71;                     % Span of small scale plane
   CBAR  = 11.32;                    % Mean Aerodynamic Chord
   XCGR  = 0.35;                     % x-coordinates of the reference cofg position
   XCG   = 0.35;                     % Paramater from Testing Function
   HX    = 160;                      % Engine angular momentum (slug-ft^2/s)
   RTOD  = 57.29578;                 % Radians to Degrees
   RM    = 1.57e-3;                  %
   
 % Parameters
   AXX      = 81.76;                   % Scaled Moment of inertia Jx
   AYY      = 2000.72;                 % Scaled Moment of inertia Jy
   AZZ      = 956.64;                  % Scaled Moment of inertia Jz
   AXZ      = 0;                       % Scaled Moment of inertia Jxz
   AXZS     = AXZ^2;                   % Square of Jxz
   XPQ      = AXZ*(AXX-AYY+AZZ);       % Used to simplify Pdot/Rdot Equations
   GAM      = AXX*AZZ-AXZ^2;           % Gamma
   XQR      = AZZ*(AZZ-AYY)+AXZS;      % Used to simplify Pdot/Rdot Equations
   ZPQ      = (AXX-AYY)*AXX+AXZS;      % Used to simplify Rdot Equation 
   YPR      = AZZ - AXX;               % Used to simplify Qdot Equation
   weight   = 5.745247;                % F-16 Weight
   GD       = 32.17;                   % Gravity Acceleration ft/s^2
   MASS     = weight/GD;               % W=mg equation
 
% Control Vector
     Thtl = u(1);                      % Throttle
     Elev = u(2);                      % Elevator
     Ail  = u(3);                      % Aileron
     Rdr  = u(4);                      % Rudder
    
    
% State Vector
    VT          = x(1);          % Freestream Airspeed
    Alpha       = x(2)*RTOD;     % Angle of Attack normalized to Degrees
    Beta        = x(3)*RTOD;     % Angle of Sideslip normalized to Degrees
    Phi         = x(4);          % Euler Angle - X Component (Bank)
    Theta       = x(5);          % Euler Angle - Y Component (Pitch)
    Psi         = x(6);          % Euler Angle - Z Component (Yaw)
    P           = x(7);          % Angular Velocity - X Component
    Q           = x(8);          % Angular Velocity - Y Component
    R           = x(9);          % Angular Velocity - Z Component
    alt         = x(12);         % Altitude 
    POW         = x(13);         % Engine Power State 

% Air data computer and engine model 
    [Amach,Qbar] = ADC(VT,alt);              % Air Data Computer
    Cpow = TGEAR(Thtl);                      % Power Command vs Throttle
    xd(13) = PDOT(POW,Cpow);                 % Rate of Change of Power
    T =k3*THRUST(POW,alt,Amach);             % Engine Thrust Model
    

% Look up tables and component buildup
    CXT     = CX(Alpha,Elev);                                                 % Non-Dimensional Force Coefficient X
    CYT     = CY(Beta,Ail,Rdr);                                               % Non-Dimensional Force Coefficient Y
    CZT     = CZ(Alpha,Beta,Elev);                                            % Non-Dimensional Force Coefficient Z
    DAil    = Ail/20;
    DRdr    = Rdr/30;
    CLT     = CL(Alpha,Beta) + DLDA(Alpha,Beta)*DAil + DLDR(Alpha,Beta)*DRdr; % Non-Dimensional Moment Coefficient X
    CMT     = CM(Alpha,Elev);                                                 % Non-Dimensional Moment Coefficient Y
    CNT     = CN(Alpha,Beta) + DNDA(Alpha,Beta)*DAil + DNDR(Alpha,Beta)*DRdr; % Non-Dimensional Moment Coefficient Z
    
% Add Damping Derivatives
    TVT = 0.5/VT;                                                             % 1/(2*Freestream Airspeed)
    B2V = B*TVT;
    CQ  = CBAR*Q*TVT;
    D   = DAMP(Alpha);           % Calculates Damping for CXq CYr CYp CZq Clr Clp Cmq Cnr Cnp respectively D1-D9
    CXT = CXT + CQ*D(1);                                             % Total force Coefficient X
    CYT = CYT + B2V * (D(2)*R + D(3)*P);                             % Total force Coefficient Y
    CZT = CZT + CQ*D(4);                                             % Total force Coefficient Z
    CLT2 = CLT + B2V*(D(5)*R + D(6)*P);                              % Total Moment Coefficient X
    CMT2 = CMT + CQ*D(7) + CZT*(XCGR-XCG);                           % Total Moment Coefficient Y
    CNT2 = CNT + B2V*(D(8)*R + D(9)*P) - CYT*(XCGR-XCG)*(CBAR/B);    % Total Moment Coefficient Z
    
% Declarations for 6-DoF Equations
    CBTA = cos(x(3));
    U    = VT*cos(x(2))*CBTA;   % Translating from VT to U
    V    = VT*sin(x(3));        % Translating from VT to V
    W    = VT*sin(x(2))*CBTA;   % Translating from VT to W
    STH  = sin(Theta);          % sin of Theta
    CTH  = cos(Theta);          % cos of Theta
    SPH  = sin(Phi);            % sin of Phi
    CPH  = cos(Phi);            % cos of Phi
    SPSI = sin(Psi);            % sin of Psi
    CPSI = cos(Psi);            % cos of Psi
    QS   = Qbar * S;            % Dynamic Pressure * Wing Planform Area
    QSB  = QS * B;              % DP*WPA*Wingspan
    RMQS = QS/MASS;               % DP*WPA/Mass (QS*RM) - -- - - -
    GCTH = GD*CTH;              % Gravity Down*cos(Theta)
    QSPH = Q*SPH;               % Angular Velocity * Sin(Phi)
    AY   = RMQS*CYT;            % ((DP*WPA)/Mass)* Force Coefficient Y
    AZ   = RMQS*CZT;            % ((DP*WPA)/Mass)* Force Coefficient Z
    
% 6-DoF Equations, Table 2.5-1 Stevens and Lewis
    
% Force Equations
    UDot  =  R*V - Q*W - GD*STH + (QS*CXT + T)/MASS; % changed to mass from RM to fit Stevens - - - -
    VDot  =  P*W - R*U + GCTH * SPH + AY;
    WDot  =  Q*U - P*V + GCTH * CPH + AZ;
    DUM   = (U*U + W*W);
    xd(1) = (U*UDot + V*VDot + W*WDot)/VT;
    xd(2) = (U*WDot - W*UDot) / DUM;
    xd(3) = (VT*VDot- V*xd(1))*CBTA/DUM;
   
% Kinematic Equations
    xd(4) = P + (STH/CTH)*(QSPH + R*CPH);
    xd(5) = Q*CPH - R*SPH;
    xd(6) = (QSPH + R*CPH)/CTH;

 % Moment Equations
    Roll    = QSB*CLT2;
    Pitch   = QS*CBAR*CMT2;
    Yaw     = QSB*CNT2;
    PQ      = P*Q;
    QR      = Q*R;
    QHX     = Q*HX;
    xd(7)   = (XPQ*PQ - XQR*QR + AZZ*Roll + AXZ*(Yaw + QHX))/GAM;   % P dot
    xd(8)   = (YPR*P*R - AXZ*(P*2 - R*2) + Pitch - R*HX)/AYY;       % Q dot
    xd(9)   = (ZPQ*PQ - XPQ*QR + AXZ*Roll + AXX*(Yaw + QHX))/GAM;   % R dot
 

    
 % Navigation Equations
    % The following, T1-T3 and S1-S8, are used to simplify the length
    % of the navigation equations. 
    T1  = SPH*CPSI; 
    T2  = CPH*STH; 
    T3  = SPH*SPSI;
    S1  = CTH*CPSI;
    S2  = CTH*SPSI; 
    S3  = T1*STH - CPH*SPSI;
    S4  = T3*STH + CPH*CPSI; 
    S5  = SPH*CTH; 
    S6  = T2*CPSI + T3;
    S7  = T2*SPSI - T1;
    S8  = CPH*CTH;
 
    xd(10) = U*S1  + V*S3 + W*S6; % North speed
    xd(11) = U*S2  + V*S4 + W*S7; % East speed
    xd(12) = U*STH - V*S5 - W*S8; % Vertical speed

     xd = [xd(1); xd(2); xd(3); xd(4); xd(5); xd(6); xd(7); xd(8); xd(9); xd(10); xd(11); xd(12); xd(13); ];