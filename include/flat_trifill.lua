-- draws a flat based triangle. mostly used by trifill.lua

function flat_trifill(xa, ya, xb, yb, xc, direction)
 slope1, slope2, xa2 = (xb - xa) / (yb - ya), (xc - xa) / (yb - ya), xa
 for scany = ya, yb, direction do
  line(round(xa), scany, round(xa2), scany)
  xa+= direction * slope1
  xa2+= direction * slope2
 end
end