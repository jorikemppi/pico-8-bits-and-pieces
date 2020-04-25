-- reflect(object, axis): flips the object along an axis. axis is entered
-- as an integer: x = 1, y = 2, z = 3. mainly used by the object importer.

function reflect(object, axis)

 if #object==0 then
  for tri in all(obj.tris) do
   tri[1], tri[3] = tri[3], tri[1]
  end
  reflect(object.verts_tri, axis)
  reflect(object.verts_normal, axis)
  return
 end
 
 for i in all(object) do
  i[axis] = -i[axis]
 end
 
end