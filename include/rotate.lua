-- rotate(object, q, axis): rotates all triangle and normal vertices q*360 degrees
-- around an axis. axis is entered as a string, for example: rotate(obj, 0.5, "x").
-- uses dot3d_rotate.lua

function rotate(object, q, axis)

 if #object==0 then
  rotate(object.verts_tri, q, axis)
  rotate(object.verts_normal, q, axis)
  return
 end
 
 sinr, cosr = sin(q), cos(q)
   
 for i in all(object) do
  i[1], i[2], i[3] = dot3d_rotate(i[1], i[2], i[3], sinr, cosr, axis)
 end

end