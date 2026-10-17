"""Dress the retained anatomical rig with the canonical hooded hero surfaces."""
from mathutils import Vector,Matrix
from reference_surface import curved_piece,reference_volume,cell_bounds
import math,bpy,bmesh


def wardrobe_material(name,color,metal=0.0,rough=.86):
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Metallic'].default_value=metal
    shader.inputs['Roughness'].default_value=rough
    return mat


def rounded_hood(image,across,lining):
    """Retain the pointed front silhouette over a bowed, closed cloth volume."""
    across=Vector(across).normalized();normal=across.cross(Vector((0,0,1))).normalized()
    u0,v0,u1,v1=cell_bounds(0)
    def mapper(u,v,side,relief,color):
        x=(u-u0)/(u1-u0);z=(v-v0)/(v1-v0)
        lateral=(x-.5)*.51;elevation=(z-.5)*.50
        dome=math.sqrt(max(.05,1-((z-.53)/.53)**2))
        width=math.sqrt(max(.16,1-(lateral/.28)**2))
        if side>0:
            depth=.118*width*dome+.008*relief
            aperture=max(0,1-((x-.63)/.24)**2-((z-.53)/.30)**2)
            depth-=.035*aperture**.65
        else:
            lateral*=.83;elevation*=.92
            depth=-(.085*width*dome+.008*relief)
        return across*lateral+normal*depth+Vector((0,0,1.815+elevation))
    obj=reference_volume('Canonical deep folded hood and scarf',image,mapper,cell_bounds(0),112,metal=.02,rough=.95,emission=.07,plain_back=True,textured_edges=False)
    obj.data.materials[1]=lining;obj.data.materials[2]=lining
    shell=bmesh.new();shell.from_mesh(obj.data)
    # The alpha contour arrives as a pixel lattice. Relax the small stair
    # steps into fabric curvature so side lighting cannot turn them into ribs.
    for _ in range(6):
        bmesh.ops.smooth_vert(shell,verts=list(shell.verts),factor=.35,use_axis_x=True,use_axis_y=True,use_axis_z=True)
    bmesh.ops.recalc_face_normals(shell,faces=list(shell.faces))
    shell.to_mesh(obj.data);shell.free()
    obj['surface_method']='Pointed canonical front, bowed closed hood with cloth sides'
    return obj


def dress(context):
    image=context['atlas'];rig=context['rig'];body=context['human']
    models=context['model_objects'];source_bind=context['bind'];rest=context['rest']
    neutral=context['base_pose']()
    bones={name:{'head':matrix.translation.copy()} for name,matrix in neutral.items()}
    for obj in list(models):
        if obj!=body:bpy.data.objects.remove(obj,do_unlink=True)
    models[:]=[body]
    # Preserve the anatomy for the gray review, but conceal the human face
    # inside the canonical faceless hood during dressed gameplay.
    # The continuous skinned undersuit closes every viewing angle. Only the
    # head stays concealed inside the faceless hood; no torso holes are masked.
    for face in body.data.polygons:
        face.material_index=1 if sum(body.data.vertices[i].co.z for i in face.vertices)/len(face.vertices)>1.67 else 0
    leather=context['leather'].node_tree.nodes.get('Principled BSDF')
    leather.inputs['Base Color'].default_value=(.085,.065,.052,1)
    leather.inputs['Roughness'].default_value=.92
    leather.inputs['Metallic'].default_value=0
    void=context['void'];void.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value=0
    void.surface_render_method='DITHERED'
    def bind(obj,weights,mat):
        per_vertex={v.index:[] for v in obj.data.vertices}
        for name,entries in weights.items():
            for ids,amount in entries:
                for index in ids:per_vertex[index].append((name,amount))
        deformation={name:neutral[name]@rest[name].inverted() for name in neutral}
        for vertex in obj.data.vertices:
            matrix=Matrix(((0,0,0,0),)*4)
            for name,amount in per_vertex[vertex.index]:matrix+=deformation[name]*amount
            vertex.co=matrix.inverted()@vertex.co
        return source_bind(obj,weights,mat)
    camera_right=Vector((.781,-.625,0))
    lining=wardrobe_material('Blue charcoal woven hood lining',(.012,.020,.032),.0,.97)
    # One continuous, fully skinned garment surface supplies every angle;
    # reference relief plates are detail, not the character's only surface.
    cloth=bpy.data.materials.new('Continuous canonical garment');cloth.use_nodes=True
    p=cloth.node_tree.nodes.get('Principled BSDF');p.inputs['Roughness'].default_value=.8;p.inputs['Metallic'].default_value=.18
    tex=cloth.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    cloth.node_tree.links.new(tex.outputs['Color'],p.inputs['Base Color'])
    body.data.materials[0]=cloth
    regions={}
    for face in body.data.polygons:
        row={}
        for index in face.vertices:
            for g in body.data.vertices[index].groups:
                name=body.vertex_groups[g.group].name;row[name]=row.get(name,0)+g.weight
        main=max(row,key=row.get);side='R' if main.endswith('.R') else 'L'
        family='hand' if main.startswith(('finger','hand')) else 'forearm' if main.startswith('forearm') else 'upper_arm' if main.startswith(('upper_arm','clavicle')) else 'thigh' if main.startswith('thigh') else 'shin' if main.startswith('shin') else 'foot' if main.startswith('foot') else 'torso'
        cell=1 if family=='torso' else dict(zip(['upper_arm','forearm','hand','thigh','shin','foot'],[7,8,9,13,14,15] if side=='R' else [4,5,6,10,11,12]))[family]
        frame=None if family=='torso' else rest[family+'.'+side].inverted()
        coords={index:(frame@body.data.vertices[index].co if frame else body.data.vertices[index].co.copy()) for index in face.vertices}
        regions[face.index]=(cell,family,coords)
    extents={}
    for cell,family,coords in regions.values():
        heights=[point.y if family!='torso' else point.z for point in coords.values()]
        lo,hi=extents.get(cell,(float('inf'),-float('inf')));extents[cell]=(min(lo,min(heights)),max(hi,max(heights)))
    uv=body.data.uv_layers.active
    for face in body.data.polygons:
        cell,family,coords=regions[face.index];u0,v0,u1,v1=cell_bounds(cell);lo,hi=extents[cell]
        for loop,index in zip(face.loop_indices,face.vertices):
            point=coords[index]
            angle=math.atan2(point.y,point.x) if family=='torso' else math.atan2(point.z,point.x)
            height=point.z if family=='torso' else point.y
            uv.data[loop].uv=(u0+(angle/(2*math.pi)+.5)*(u1-u0),v0+max(0,min(1,(height-lo)/max(.001,hi-lo)))*(v1-v0))
    def adopt(obj,bone):return bind(obj,{bone:[(list(range(len(obj.data.vertices))),1)]},None)
    def piece(label,cell,center,up,width,height,radius,bone,metal=.4,across=None,solid=False):
        up=Vector(up).normalized()
        cross=Vector(across) if across is not None else camera_right-up*camera_right.dot(up)
        obj=curved_piece(label,image,cell,center,cross,up,width,height,radius,metal,solid=solid)
        return adopt(obj,bone)
    hood=rounded_hood(image,camera_right,lining)
    weights={}
    for v in hood.data.vertices:
        head=max(0,min(1,(v.co.z-1.66)/.10))
        for name,amount in [('head',head),('spine_upper',1-head)]:
            if amount:weights.setdefault(name,[]).append(([v.index],amount))
    bind(hood,weights,None)
    cuirass=curved_piece('Layered etched dark cuirass',image,1,(0,-.025,1.365),camera_right,(0,0,1),.52,.60,.19,.28)
    weights={}
    for vertex in cuirass.data.vertices:
        upper=max(0,min(1,(vertex.co.z-1.17)/.29))
        for name,amount in [('spine_mid',1-upper),('spine_upper',upper)]:
            if amount:weights.setdefault(name,[]).append(([vertex.index],amount))
    bind(cuirass,weights,None)
    coat=curved_piece('Layered long coat front and tassets',image,2,(0,-.08,.87),camera_right,(0,0,1),.62,.68,.16,.20)
    weights={}
    for v in coat.data.vertices:
        lower=max(0,min(1,(.99-v.co.z)/.24))
        side='L' if v.co.x>0 else 'R'
        for name,amount in [('pelvis',1-lower),('skirt.'+side,lower)]:
            if amount:weights.setdefault(name,[]).append(([v.index],amount))
    bind(coat,weights,None)
    mantle=curved_piece('Torn layered hooded mantle',image,3,(0,.17,.99),(1,0,0),(0,0,1),.72,1.28,.026,.05,96)
    weights={}
    for v in mantle.data.vertices:
        column=min(2,max(0,round((v.co.x/.72+.5)*2)))
        low=max(0,min(1,(1.4-v.co.z)/.62))
        for name,amount in [(f'cloak_upper_{column}',1-low),(f'cloak_lower_{column}',low)]:
            if amount:weights.setdefault(name,[]).append(([v.index],amount))
    bind(mantle,weights,None)
    # The near/right arm is cyan; the far/left arm carries ember. Each region
    # has its own canonical surface, never a repeated whole-torso texture.
    for side,cells in [('R',(7,8,9,13,14,15)),('L',(4,5,6,10,11,12))]:
        shoulder=bones['upper_arm.'+side]['head'];elbow=bones['forearm.'+side]['head'];wrist=bones['hand.'+side]['head']
        hip=bones['thigh.'+side]['head'];knee=bones['shin.'+side]['head'];ankle=bones['foot.'+side]['head']
        def limb(label,cell,start,end,width,radius,bone,height_scale=1):
            return piece(label+' '+side,cell,(start+end)*.5,start-end,width,(start-end).length*height_scale,radius,bone,solid=True)
        limb('Pointed layered shoulder harness',cells[0],shoulder+Vector((0,0,.065)),elbow,.29,.055,'upper_arm.'+side,1.1)
        limb('Etched crystal vambrace',cells[1],elbow,wrist,.24,.04,'forearm.'+side,1.13)
        # Keep the real phalanges visible and separately articulated. The
        # gauntlet covers only the back of the palm, not all fingers as a card.
        finger=bones['finger3-1.'+side]['head']
        limb('Ornate articulated gauntlet',cells[2],wrist,finger,.15,.037,'hand.'+side,1.12)
        limb('Strapped layered thigh armor',cells[3],hip,knee,.28,.075,'thigh.'+side,1.03)
        limb('Etched crystal greave',cells[4],knee,ankle,.225,.05,'shin.'+side,1.06)
        piece('Forged strapped boot '+side,cells[5],ankle+Vector((0,-.10,-.014)),(0,0,1),.25,.235,.085,'foot.'+side,.4,solid=True)
    return len(models)
