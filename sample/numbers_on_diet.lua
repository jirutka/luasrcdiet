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
0,
16,
65536,
3735928559,
4294967295,
68719476735,
16,
4095,
-- integers
12345,
-12345,
123,
12300,
123,
123,
123,
123e3,
12345e5,
-- fractions
0,
123.45,
.12345,
.12345,
1.2345,
12.345,
.012345,
12345e-8,
-- scientific
0,
0,
0,
0,
12345e96,
12345e-104,
12345e96,
12345,
12340,
123400,
1234e3,
1234,
123.4,
123.4,
1.234,
.1234,
.001234,
1234e-7,
12345e95,
12345e95,
12345e96,
12345e100,
12345e100,
12345e100,
}
