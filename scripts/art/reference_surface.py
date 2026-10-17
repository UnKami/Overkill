"""Closed, sculpted reference surfaces with original-art UVs, not sprite cards.

Original images are read as surface references. No bitmap is edited. Alpha
defines silhouette topology; interior relief and curved cross sections provide
real front/back volume, normals and side walls for Blender and glTF skinning.
"""
import bpy,numpy as np,math
from collections import Counter
from mathutils import Vector

def reference_volume(name,image,mapper,bounds=(0,0,1,1),resolution=128,polygon=None,metal=.45,rough=.64,emission=.16,plain_back=False,textured_edges=False):
    w,h=image.size
    pixels=np.empty(w*h*4,dtype=np.float32);image.pixels.foreach_get(pixels)
    pixels=pixels.reshape(h,w,4)
    u0,v0,u1,v1=bounds
    us=np.linspace(u0,u1,resolution+1);vs=np.linspace(v0,v1,resolution+1)
    xs=np.clip((us*(w-1)).astype(int),0,w-1);ys=np.clip((vs*(h-1)).astype(int),0,h-1)
    rgba=pixels[ys[:,None],xs[None,:]]
    mask=rgba[:,:,3]>.4
    if polygon:
        xx,yy=np.meshgrid(us,vs);inside=np.zeros_like(mask)
        for a,b in zip(polygon,polygon[1:]+polygon[:1]):
            ax,ay=a;bx,by=b
            inside ^= ((ay>yy)!=(by>yy)) & (xx<(bx-ax)*(yy-ay)/(by-ay+1e-10)+ax)
        mask &= inside
    distance=np.zeros_like(rgba[:,:,0]);layer=mask.copy()
    for _ in range(22):
        distance+=layer
        layer &= np.roll(layer,1,0)&np.roll(layer,-1,0)&np.roll(layer,1,1)&np.roll(layer,-1,1)
        layer[0]=False;layer[-1]=False;layer[:,0]=False;layer[:,-1]=False
    distance/=max(1,distance.max())
    faces=[];keys=set()
    for y in range(resolution):
        for x in range(resolution):
            corners=[(y,x),(y,x+1),(y+1,x+1),(y+1,x)]
            if all(mask[a,b] for a,b in corners):faces.append(corners);keys.update(corners)
    keys=sorted(keys);indices={key:i for i,key in enumerate(keys)}
    points=[];uv=[]
    for side in (1,-1):
        for y,x in keys:
            color=rgba[y,x,:3]
            relief=float(distance[y,x])*.8+float(np.clip(color.max()-.45,0,.55))*.2
            points.append(mapper(float(us[x]),float(vs[y]),side,relief,color))
            uv.append((float(us[x]),float(vs[y])))
    n=len(keys);polygons=[];materials=[];edge_count=Counter();edge_directions={}
    for quad in faces:
        face=[indices[k] for k in quad]
        polygons.append(face);materials.append(0)
        polygons.append([i+n for i in reversed(face)]);materials.append(2 if plain_back else 0)
        for a,b in zip(face,face[1:]+face[:1]):
            edge=tuple(sorted((a,b)));edge_count[edge]+=1;edge_directions[edge]=(a,b)
    for (a,b),count in edge_count.items():
        if count==1:
            a,b=edge_directions[(a,b)]
            polygons.append([b,a,a+n,b+n]);materials.append(0 if textured_edges else 1)
    data=bpy.data.meshes.new(name);data.from_pydata(points,[],polygons);data.update()
    layer=data.uv_layers.new(name='Canonical reference UV')
    for loop in data.loops:layer.data[loop.index].uv=uv[loop.vertex_index]
    mat=bpy.data.materials.new(name+' reference surface');mat.use_nodes=True
    p=mat.node_tree.nodes.get('Principled BSDF');p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    mat.node_tree.links.new(tex.outputs['Color'],p.inputs['Emission Color']);p.inputs['Emission Strength'].default_value=emission
    edge=bpy.data.materials.new(name+' sculpted edge');edge.use_nodes=True
    p=edge.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(.035,.041,.05,1);p.inputs['Metallic'].default_value=.5;p.inputs['Roughness'].default_value=.6
    data.materials.append(mat);data.materials.append(edge)
    if plain_back:
        backing=bpy.data.materials.new(name+' plain backing');backing.use_nodes=True
        p=backing.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(.045,.052,.063,1);p.inputs['Metallic'].default_value=metal*.25;p.inputs['Roughness'].default_value=.88
        data.materials.append(backing)
    for face,index in zip(data.polygons,materials):face.material_index=index;face.use_smooth=True
    obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj)
    obj['reference_image']=image.filepath;obj['surface_method']='Closed curved volume with canonical UV and relief'
    return obj

def cell_bounds(cell):
    return (cell%4/4,(3-cell//4)/4,(cell%4+1)/4,(4-cell//4)/4)

def curved_piece(name,image,cell,center,across,up,width,height,radius,metal=.4,resolution=80,solid=False):
    center=Vector(center);across=Vector(across).normalized();up=Vector(up).normalized()
    normal=across.cross(up).normalized()
    bounds=cell_bounds(cell);u0,v0,u1,v1=bounds
    def mapper(u,v,side,relief,color):
        x=((u-u0)/(u1-u0)-.5)*width;z=((v-v0)/(v1-v0)-.5)*height
        depth=radius*math.sqrt(max(.12,1-(x/(width*.55))**2))+.008*relief
        return center+across*x+up*z+normal*(depth if side>0 else (-depth if solid else depth-.012))
    return reference_volume(name,image,mapper,bounds,resolution,metal=metal,emission=.10,plain_back=False,textured_edges=False)





