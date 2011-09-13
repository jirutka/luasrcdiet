-- number samples in lieu of automatic testing PUBLIC DOMAIN 2008
-- note: not comprehensive!
-- note: negative numbers are really two tokens, but are included
--       here for convenience
--
return{
-- simple numbers
0,
1,
-1,
-- hexadecimal
0x0,
0x10,
0x10000,
0xDEADBEEF,
0xFFFFFFFF,
0xFFFFFFFFF,
0x0010,
0X0FFF,
-- integers
12345,
-12345,
00123,
12300,
123.,
123.0,
123.00000,
123000,
1234500000,
-- fractions
.000,
123.45,
.12345,
0.12345,
1.23450000,
12.345,
.012345,
.00012345,
-- scientific
0e0,
0.0e0,
0.000e1,
.000e-1,
1.2345e+100,
0001.2345e-100,
0001.2345000e100,
1.234500e+4,
1234e1,
1234e2,
1234e3,
12.34e2,
12.34e1,
1234e-1,
1234e-3,
1234e-4,
1234e-6,
1234e-7,
0.12345e+100,
.12345e+100,
1.2345e+100,
12345.e+100,
12345.0e+100,
12345.000e+100,
}
