-- translate(object, x, y, z): translates object.

function translate(object, x, y, z)
 for i in all(object.verts_tri) do
  i[1]+=x
  i[2]+=y
  i[3]+=z
 end
end