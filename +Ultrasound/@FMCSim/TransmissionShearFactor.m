function out=TransmissionShearFactor(obj,incidentAngle)
cosineIncidentAngle=cos(incidentAngle);
R0=obj.medium1_density;
R1=obj.medium2_density;
R2=obj.medium1_velocity;
R3=obj.medium2_velocity;
R4=obj.medium2_velocityShear;
R5=cosineIncidentAngle;

I2 = 2;
I1 = 1;
I0 = -1;
I3 = 4;

R6 = Square( R5);
R7 = Square( R2);
R8 = Square( R2);
R9 = Reciprocal( R8);
R8 = I0;
R8 = R8 + R6;
R10 = Square( R3);
R11 = R8 * R10;
R12 = R7 + R11;
R13 = R9 * R12;
R14 = Sqrt( R13);
R15 = - R6;
R16 = I1;
R16 = R16 + R15;
R17 = Sqrt( R16);
R18 = Reciprocal( R2);
R19 = R17 * R18 * R4;
R20 = ArcSin( R19);
R21 = I2;
R21 = R21 * R20;
R22 = Cos( R21);
R23 = R0 * R7 * R14 * R22;
R24 = Square( R22);
R25 = R5 * R1 * R2 * R3 * R24;
R24 = Square( R4);
R26 = R6 * R0;
R27 = - R26;
R26 = Sin( R21);
R28 = R5 * R17 * R1 * R26;
R26 = R0 + R27 + R28;
R27 = I2;
R27 = R27 * R14 * R24 * R26;
R23 = R23 + R25 + R27;
R25 = Reciprocal( R23);
R23 = I3;
R23 = R23 * R5 * R17 * R0 * R2 * R14 * R4 * R25;

out=R23;

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
% 		4 Integer registers
% 		29 Real registers
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
% 		I2 = 2
% 		I1 = 1
% 		I0 = -1
% 		I3 = 4
% 		Result = R23
% 
% 1	R6 = Square[ R5]
% 2	R7 = Square[ R2]
% 3	R8 = Square[ R2]
% 4	R9 = Reciprocal[ R8]
% 5	R8 = I0
% 6	R8 = R8 + R6
% 7	R10 = Square[ R3]
% 8	R11 = R8 * R10
% 9	R12 = R7 + R11
% 10	R13 = R9 * R12
% 11	R14 = Sqrt[ R13]
% 12	R15 = - R6
% 13	R16 = I1
% 14	R16 = R16 + R15
% 15	R17 = Sqrt[ R16]
% 16	R18 = Reciprocal[ R2]
% 17	R19 = R17 * R18 * R4
% 18	R20 = ArcSin[ R19]
% 19	R21 = I2
% 20	R21 = R21 * R20
% 21	R22 = Cos[ R21]
% 22	R23 = R0 * R7 * R14 * R22
% 23	R24 = Square[ R22]
% 24	R25 = R5 * R1 * R2 * R3 * R24
% 25	R24 = Square[ R4]
% 26	R26 = R6 * R0
% 27	R27 = - R26
% 28	R26 = Sin[ R21]
% 29	R28 = R5 * R17 * R1 * R26
% 30	R26 = R0 + R27 + R28
% 31	R27 = I2
% 32	R27 = R27 * R14 * R24 * R26
% 33	R23 = R23 + R25 + R27
% 34	R25 = Reciprocal[ R23]
% 35	R23 = I3
% 36	R23 = R23 * R5 * R17 * R0 * R2 * R14 * R4 * R25
% 37	Return
