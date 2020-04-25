-- special importer version of send_to_queue with UI features. use send_to_queue.lua instead.

function send_to_queue(object)

 for i=1,#object.tris do

  tri,v,depth,mat={},{},0,material[object.mats[i]]
  for j=1,3 do
   add(tri,object.verts_tri[object.tris[i][j]])
   trij=tri[j]
   add(v,flatten_point(trij[1],trij[2],trij[3]))
   depth+=trij[3]
  end
  add(tri,object.verts_normal[object.tris[i][4]])

  if ((v[2][1]-v[1][1])*(v[3][2]-v[1][2])-(v[3][1]-v[1][1])*(v[2][2]-v[1][2]))/2>0 then  

   add(rq[object.layers[i]], {v[1],v[2],v[3],object.mats[i],mat,mid(1,128,flr((tri[4][3])*mat.diffuse)+mat.ambient),depth, i})
   
  end
 end

end