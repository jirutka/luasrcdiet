
-- ';' optimization
-------------------

-- in-between
local foo=100 local bar=50
local foo=100 local bar=50
local foo=100 bar=50
local foo=100 bar=50

-- end of the line
local foo=100

-- after function
fish(10)cow(20)
do
fish(10)return
end

-- f("string") optimization
---------------------------

-- intended result
fish1"cow"fish2'cow'fish3[[cow]]

-- can be optimized
fish4"cow"fish5'cow'fish6[[cow]]

-- added some whitespace
fish7"cow"
fish8'cow'fish9[[cow]]
