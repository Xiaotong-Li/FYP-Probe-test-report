function out=TransmissionLongFactor(obj,incidentAngle)
cosineIncidentAngle=cos(incidentAngle);
R0=obj.medium1_density;
R1=obj.medium2_density;
R2=obj.medium1_velocity;
R3=obj.medium2_velocity;
R4=obj.medium2_velocityShear;
R5=cosineIncidentAngle;

I1=2;
I0=1;
I2=-1;

R6 = Square(R5);
R7 = - R6;
R8 = I0;
R8 = R8 + R7;
R9 = Sqrt(R8);
R10 = Reciprocal( R2);
R11 = R9 * R10 * R4;
R12 = ArcSin( R11);
R13 = I1;
R13 = R13 * R12;
R14 = Cos( R13);
R15 = Square( R3);
R16 = Square( R2);
R17 = Reciprocal( R16);
R16 = Square( R2);
R18 = I2;
R18 = R18 + R6;
R18 = R18 * R15;
R16 = R16 + R18;
R17 = R17 * R16;
R16 = Sqrt( R17);
R17 = R0 * R2 * R3 * R16 * R14;
R16 = Square( R14);
R18 = R5 * R1 * R15 * R16;
R16 = Square( R4);
R19 = R9 * R10 * R3;
R20 = ArcSin( R19);
R19 = I1;
R19 = R19 * R20;
R20 = Sin( R19);
R19 = R9 * R0;
R21 = Sin( R13);
R22 = R5 * R1 * R21;
R19 = R19 + R22;
R16 = R16 * R20 * R19;
R17 = R17 + R18 + R16;
R18 = Reciprocal( R17);
R17 = I1;
R17 = R17 * R5 * R0 * R2 * R3 * R14 * R18;
out=R17;
end
function y=ArcSin(x)
y=asin(x);
end
function y=Square(x)
y=x*x;
end
function y=Reciprocal(x)
y=1./x;
end
function y=Sqrt(x)
y=sqrt(x);
end
function y=Cos(x)
y=cos(x);
end
function y=Sin(x)
y=sin(x);
end
% arguments are 
% TransmissionLongFunction[rho1, rho2, Vp1, Vp2, Vs2, cfp1]
% 6 arguments
% 		3 Integer registers
% 		23 Real registers
% 		Underflow checking off
% 		Overflow checking off
% 		Integer overflow checking on
% 		RuntimeAttributes -> {}
% 
% 		R0 = A1
% 		R1 = A2
% 		R2 = A3
% 		R3 = A4
% 		R4 = A5
% 		R5 = A6
% 		I1 = 2
% 		I0 = 1
% 		I2 = -1
% 		Result = R17
% 
% 1	R6 = Square[ R5]
% 2	R7 = - R6
% 3	R8 = I0
% 4	R8 = R8 + R7
% 5	R9 = Sqrt[ R8]
% 6	R10 = Reciprocal[ R2]
% 7	R11 = R9 * R10 * R4
% 8	R12 = ArcSin[ R11]
% 9	R13 = I1
% 10	R13 = R13 * R12
% 11	R14 = Cos[ R13]
% 12	R15 = Square[ R3]
% 13	R16 = Square[ R2]
% 14	R17 = Reciprocal[ R16]
% 15	R16 = Square[ R2]
% 16	R18 = I2
% 17	R18 = R18 + R6
% 18	R18 = R18 * R15
% 19	R16 = R16 + R18
% 20	R17 = R17 * R16
% 21	R16 = Sqrt[ R17]
% 22	R17 = R0 * R2 * R3 * R16 * R14
% 23	R16 = Square[ R14]
% 24	R18 = R5 * R1 * R15 * R16
% 25	R16 = Square[ R4]
% 26	R19 = R9 * R10 * R3
% 27	R20 = ArcSin[ R19]
% 28	R19 = I1
% 29	R19 = R19 * R20
% 30	R20 = Sin[ R19]
% 31	R19 = R9 * R0
% 32	R21 = Sin[ R13]
% 33	R22 = R5 * R1 * R21
% 34	R19 = R19 + R22
% 35	R16 = R16 * R20 * R19
% 36	R17 = R17 + R18 + R16
% 37	R18 = Reciprocal[ R17]
% 38	R17 = I1
% 39	R17 = R17 * R5 * R0 * R2 * R3 * R14 * R18
% 40	Return