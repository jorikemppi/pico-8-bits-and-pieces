-- returns an array of 128 color values with two colours and pattern data.
-- uses shades.lua

function generate_gradient(steps, start)

 i, i2, gradient = 1, 1, {}

 while i < steps[1] do
  add(gradient,start)
  i += 1
 end
 
 while i < 129 do
  curr_col, curr_shade = i2 - 1 + start, 1

  if i2 < #steps then
   curr_shade = flr(16 / (steps[i2 + 1] - steps[i2]) * (i - steps[i2])) + 1   
  end
  add(gradient, 17 * curr_col + 16 + shades[curr_shade])
  i += 1
  if i == steps[i2 + 1] then i2 += 1 end
 end
 
 return gradient
 
end