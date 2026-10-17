"""Reference-faithful relic volume, retaining canonical silhouette and surfaces."""
import bpy,math,bmesh
import numpy as np
from mathutils import Vector
from reference_surface import reference_volume

def modeled_sword(bind,bone='prop',label='Iron Strike'):
    """Broad molten cutting core, forged spine and a graspable round handle."""
    def material(name,color,metal,rough,glow=0):
        mat=bpy.data.materials.new('Sword '+name);mat.use_nodes=True
        p=mat.node_tree.nodes['Principled BSDF']
        p.inputs['Base Color'].default_value=(*color,1)
        p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
        p.inputs['Emission Color'].default_value=(*color,1);p.inputs['Emission Strength'].default_value=glow
        return mat
    steel=material('dark forged spine',(.095,.115,.145),.86,.32)
    bevel=material('silver chamfers',(.42,.46,.50),.88,.27)
    bronze=material('warm fittings',(.29,.145,.046),.76,.38)
    molten=material('amber cutting core',(.20,.037,.006),.46,.49,.45)
    dark=material('cooled cutting edge',(.065,.024,.012),.65,.42,.035)
    hot=material('incandescent fractures',(.72,.13,.003),.08,.36,.65)
    leather=material('dark grip binding',(.015,.011,.008),.02,.84)
    paths=[[(.20,.16),(.30,.25),(.22,.34),(.42,.43),(.30,.53),(.35,.63),(.45,.71)],
           [(.30,.25),(.06,.30)],[(.22,.34),(.60,.38)],[(.42,.43),(.09,.49)],
           [(.30,.53),(.61,.58)],[(.35,.63),(.08,.67)]]
    # Packed PBR maps belong to the modeled blade surface. Broad cooled metal
    # retains lighting; only the narrow fractures radiate strongly. This avoids
    # the uniformly emissive orange silhouette hiding the actual bevels.
    width,height=512,1024
    u,v=np.meshgrid(np.linspace(0,1,width),np.linspace(0,1,height))
    z=.125+v*.615
    rng=np.random.default_rng(47048)
    def grain(nx,ny):
        values=rng.random((ny+1,nx+1))
        x=u*nx;y=v*ny;ix=np.minimum(x.astype(int),nx-1);iy=np.minimum(y.astype(int),ny-1)
        fx=x-ix;fy=y-iy;fx=fx*fx*(3-2*fx);fy=fy*fy*(3-2*fy)
        return ((1-fx)*values[iy,ix]+fx*values[iy,ix+1])*(1-fy)+((1-fx)*values[iy+1,ix]+fx*values[iy+1,ix+1])*fy
    broad=grain(14,28);fine=grain(85,170)
    distance=np.full(u.shape,10.0)
    for path in paths:
        for a,b in zip(path,path[1:]):
            ax,ay=a[0]*.21,a[1];bx,by=b[0]*.21,b[1]
            dx,dy=bx-ax,by-ay
            t=np.clip(((u*.21-ax)*dx+(z-ay)*dy)/(dx*dx+dy*dy),0,1)
            distance=np.minimum(distance,np.sqrt((u*.21-ax-t*dx)**2+(z-ay-t*dy)**2))
    fracture=np.exp(-(distance/.0018)**2);halo=np.exp(-(distance/.012)**2)
    heat=.22+.50*broad+.12*fine
    base=np.array([.042,.014,.008])+heat[...,None]*np.array([.27,.043,.006])+halo[...,None]*np.array([.15,.021,.001])
    base=base*(1-fracture[...,None])+fracture[...,None]*np.array([.76,.145,.003])
    emission=heat[...,None]*np.array([.038,.006,.0003])+halo[...,None]*np.array([.12,.014,.0005])+fracture[...,None]*np.array([.65,.12,.002])
    p=molten.node_tree.nodes['Principled BSDF']
    for suffix,pixels,socket in [('surface',base,'Base Color'),('heat',emission,'Emission Color')]:
        image=bpy.data.images.new(label+' forged blade '+suffix,width=width,height=height,alpha=True)
        image.colorspace_settings.name='Non-Color'
        rgba=np.concatenate((np.clip(pixels,0,1),np.ones((height,width,1))),axis=2).astype(np.float32)
        image.pixels.foreach_set(rgba.ravel());image.pack()
        texture=molten.node_tree.nodes.new('ShaderNodeTexImage');texture.image=image
        molten.node_tree.links.new(texture.outputs['Color'],p.inputs[socket])
    parts=[]
    def finish(obj,name,mat,smooth=False):
        obj.name=label+' '+name
        bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
        bpy.context.view_layer.objects.active=obj
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        obj.data.materials.append(mat)
        for face in obj.data.polygons:face.use_smooth=smooth
        parts.append(obj);return obj
    def cylinder(name,at,radius,depth,mat,axis=(0,0,1),vertices=16):
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=at)
        obj=bpy.context.object;obj.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
        return finish(obj,name,mat)
    def rod(name,a,b,radius,mat,vertices=8):
        a,b=Vector(a),Vector(b)
        return cylinder(name,(a+b)*.5,radius,(b-a).length,mat,b-a,vertices)
    def mesh(name,vertices,faces,mat):
        data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update()
        shell=bmesh.new();shell.from_mesh(data);bmesh.ops.recalc_face_normals(shell,faces=list(shell.faces));shell.to_mesh(data);shell.free()
        obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj)
        return finish(obj,name,mat)
    # Longitudinal silhouette measured from the original artwork-derived mesh.
    # The tip stays exactly 0.74m from the established palm socket.
    profile=[(.125,-.030,.032,.026),(.16,-.064,.060,.035),(.21,-.113,.088,.040),
             (.30,-.130,.076,.040),(.42,-.123,.064,.037),(.54,-.117,.063,.033),
             (.63,-.092,.056,.027),(.70,-.049,.029,.016)]
    cross=[(0,0),(.08,-.45),(.52,-1),(.85,-.55),(1,0),(.85,.55),(.52,1),(.08,.45)]
    points=[(left+(right-left)*u,depth*v,z) for z,left,right,depth in profile for u,v in cross]
    tip=len(points);points.append((0,0,.74));faces=[];indices=[]
    for j in range(len(profile)-1):
        for i in range(8):
            a=j*8+i;b=j*8+(i+1)%8;c=(j+1)*8+(i+1)%8;d=(j+1)*8+i
            faces.extend([(a,b,c),(a,c,d)])
            indices.extend([1 if i in (0,7) else 0]*2)
    last=(len(profile)-1)*8
    for i in range(8):faces.append((last+i,last+(i+1)%8,tip));indices.append(0)
    faces.append(tuple(reversed(range(8))));indices.append(0)
    core=mesh('faceted molten blade',points,faces,molten);core.data.materials.append(dark)
    for face,index in zip(core.data.polygons,indices):face.material_index=index
    uv=core.data.uv_layers.new(name='Forged blade surface')
    for loop in core.data.loops:
        vertex=loop.vertex_index
        if vertex==tip:coordinate=(.5,1)
        else:coordinate=(cross[vertex%8][0],(profile[vertex//8][0]-.125)/.615)
        uv.data[loop.index].uv=coordinate
    def section(z):
        for a,b in zip(profile,profile[1:]+[(.74,0,0,0)]):
            if z<=b[0]:
                t=max(0,min(1,(z-a[0])/(b[0]-a[0])))
                return tuple(a[i]*(1-t)+b[i]*t for i in range(1,4))
        return (0,0,0)
    def surface(u,z,side,offset=0):
        left,right,depth=section(z);knots=[(0,0),(.08,.45),(.52,1),(.85,.55),(1,0)]
        height=0
        for a,b in zip(knots,knots[1:]):
            if u<=b[0]:height=a[1]+(b[1]-a[1])*(u-a[0])/(b[0]-a[0]);break
        return Vector((left+(right-left)*u,-side*(depth*height+offset),z))
    # Separate closed steel plates on both faces; real beveled thickness shows
    # during a wrist roll rather than mirroring a picture onto the blade side.
    for side in (-1,1):
        for a,b in [(.165,.245),(.252,.345),(.352,.455),(.462,.565),(.572,.655),(.662,.718)]:
            front=[surface(.69,a,side,.003),surface(.98,a,side,.003),surface(.98,b,side,.003),surface(.69,b,side,.003)]
            back=[p+Vector((0,side*.006,0)) for p in front]
            plate=mesh('segmented steel spine',front+back,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],steel)
            bpy.context.view_layer.objects.active=plate
            modifier=plate.modifiers.new('Forged spine bevel','BEVEL');modifier.width=.002;modifier.segments=1
            modifier.affect='EDGES';modifier.material=1;plate.data.materials.append(bevel)
            bpy.ops.object.modifier_apply(modifier=modifier.name)
        for path in paths:
            for a,b in zip(path,path[1:]):
                samples=[surface(a[0]+(b[0]-a[0])*i/6,a[1]+(b[1]-a[1])*i/6,side,.0016) for i in range(7)]
                for p,q in zip(samples,samples[1:]):rod('molten fracture',p,q,.0007,hot,6)
    cylinder('round grip',(0,0,.005),.025,.19,leather,vertices=24)
    for z in [-.080,-.047,-.014,.019,.052,.085]:
        cylinder('grip steel band',(0,0,z),.027,.009,steel,vertices=8)
    for i in range(4):
        angle=math.tau*(i+.5)/4;axis=Vector((math.cos(angle),math.sin(angle),0))
        rod('handle amber channel',axis*.025+Vector((0,0,-.075)),axis*.025+Vector((0,0,.089)),.0024,molten)
    cylinder('octagonal guard',(0,0,.112),.074,.028,steel,vertices=8)
    cylinder('guard warm collar',(0,0,.096),.034,.008,bronze,vertices=8)
    cylinder('caged amber pommel',(0,0,-.115),.040,.039,steel,vertices=8)
    for side in (-1,1):
        cylinder('pommel inset',(0,side*.039,-.115),.025,.006,molten,(0,1,0),8)
        cylinder('guard inset',(0,side*.072,.112),.023,.005,molten,(0,1,0),8)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    obj=bpy.context.view_layer.objects.active
    smooth=[p.use_smooth for p in obj.data.polygons]
    obj=bind(obj,bone,None)
    for face,value in zip(obj.data.polygons,smooth):face.use_smooth=value
    obj['construction']='Modeled faceted molten blade, closed steel spine and round grip'
    obj['grip_radius_m']=.025;obj['blade_tip_m']=.74
    return obj

def modeled_hammer(bind):
    """Molten twin cores in a forged cage, with volume on every viewing axis."""
    def mat(name,color,metal,rough,glow=0):
        result=bpy.data.materials.new(name);result.use_nodes=True
        p=result.node_tree.nodes['Principled BSDF']
        p.inputs['Base Color'].default_value=(*color,1)
        p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
        p.inputs['Emission Color'].default_value=(*color,1)
        p.inputs['Emission Strength'].default_value=glow
        return result
    steel=mat('Hammer forged dark steel',(.085,.105,.125),.82,.31)
    bronze=mat('Hammer warm bevels',(.29,.13,.035),.74,.36)
    molten=mat('Hammer molten amber cores',(.65,.073,.003),.22,.32,.65)
    fissure=mat('Hammer incandescent seams',(.9,.17,.005),.10,.27,1.2)
    grip=mat('Hammer bound leather',(.017,.012,.010),.02,.82)
    parts=[]
    def finish(obj,name,material,smooth=True):
        obj.name=name
        bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
        obj.data.materials.append(material)
        for face in obj.data.polygons:face.use_smooth=smooth
        parts.append(obj);return obj
    def cylinder(name,at,radius,depth,material,axis=(0,0,1),vertices=24):
        bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=at)
        obj=bpy.context.object;obj.rotation_euler=Vector(axis).to_track_quat('Z','Y').to_euler()
        return finish(obj,name,material)
    def rod(name,a,b,radius,material):
        a,b=Vector(a),Vector(b)
        return cylinder(name,(a+b)*.5,radius,(b-a).length,material,b-a,8)
    def gem(name,at,scale,material,subdivisions=1):
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions,radius=1,location=at)
        obj=bpy.context.object;obj.scale=scale;return finish(obj,name,material,False)
    def collar(x):
        # Closed annular metal, with an open centre. Cylinder end caps would
        # cover the molten core as soon as the head turns toward the camera.
        vertices=[]
        for xx,r in [(x-.010,.15),(x+.010,.15),(x+.010,.132),(x-.010,.132)]:
            vertices.extend((xx,r*math.cos(math.tau*i/8),.39+r*math.sin(math.tau*i/8)) for i in range(8))
        faces=[]
        for ring in range(4):
            for i in range(8):
                faces.append((ring*8+i,ring*8+(i+1)%8,((ring+1)%4)*8+(i+1)%8,((ring+1)%4)*8+i))
        mesh=bpy.data.meshes.new('Open octagonal collar');mesh.from_pydata(vertices,[],faces);mesh.update()
        obj=bpy.data.objects.new('Open octagonal collar',mesh);bpy.context.scene.collection.objects.link(obj)
        bpy.context.view_layer.objects.active=obj;obj.select_set(True)
        finish(obj,'Open octagonal collar',steel,False)
    cylinder('Through shaft',(0,0,.17),.025,.54,steel)
    cylinder('Palm leather grip',(0,0,.04),.028,.25,grip)
    for z in [-.085,-.055,-.025,.005,.035,.065,.095,.125]:
        cylinder('Leather binding ridge',(0,0,z),.029,.009,bronze)
    for z in [.19,.235,.28]:cylinder('Forged shaft collar',(0,0,z),.037,.025,steel)
    gem('Molten pommel',(0,0,-.12),(.041,.041,.042),molten)
    cylinder('Pommel cage',(0,0,-.12),.042,.043,steel,vertices=8)
    cylinder('Forged head crossbar',(0,0,.39),.094,.36,steel,(1,0,0),8)
    for sign in (-1,1):
        center=Vector((sign*.18,0,.39))
        core=gem('Faceted molten striking core',center,(.135,.147,.147),molten,2)
        # Veins follow the solid polyhedron, including its rear surface.
        for edge in core.data.edges:
            a,b=(core.data.vertices[i].co.copy() for i in edge.vertices)
            rod('Molten vein',a,b,.0015,fissure)
        for x in [sign*.075,sign*.27]:
            collar(x)
        for i in range(8):
            angle=math.tau*i/8
            yz=Vector((0,.140*math.cos(angle),.140*math.sin(angle)))
            rod('Forged core cage',Vector((sign*.070,0,.39))+yz,
                Vector((sign*.28,0,.39))+yz,.009,bronze)
        for i in range(5):
            angle=math.tau*(i+.15)/5
            at=center+Vector((sign*.11,.10*math.cos(angle),.10*math.sin(angle)))
            gem('Molten edge splinter',at,(.020,.017,.028),molten)
    for sign in (-1,1):
        cylinder('Recessed central bezel',(0,sign*.099,.39),.069,.015,bronze,(0,1,0),8)
        gem('Central amber octagon',(0,sign*.110,.39),(.045,.016,.061),molten)
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
    obj=bpy.context.view_layer.objects.active
    obj['construction']='Modeled shaft, faceted twin cores and circumferential forged cage'
    return bind(obj,'prop',None)

def build_relic(root,relic_id,kind,bind):
    if kind=='hammer':return modeled_hammer(bind)
    if kind in ('sword','blades'):
        modeled_sword(bind,'prop','Iron Strike')
        if kind=='blades':modeled_sword(bind,'secondary','Twin Blades left')
        return
    number=int(relic_id.split('-')[1])
    path=next((root/'assets/relics/active').glob(f'rel_{number:02d}_*_object.png'))
    image=bpy.data.images.load(str(path),check_existing=True);image.pack()
    w,h=image.size
    def part(label,bone,origin,units,thickness,polygon=None,rotation=0):
        if polygon:polygon=[(x/w,1-y/h) for x,y in polygon]
        def mapper(u,v,side,relief,color):
            x=(u*w-origin[0])*units;z=((1-origin[1]/h)-v)*-h*units
            x,z=x*math.cos(rotation)-z*math.sin(rotation),x*math.sin(rotation)+z*math.cos(rotation)
            # A thick, rounded volume plus fine relief, closed by side walls.
            depth=thickness*(.35+.65*relief)
            return (x,-side*depth,z)
        obj=reference_volume(label,image,mapper,resolution=144,polygon=polygon,metal=.42,rough=.66,emission=.22)
        return bind(obj,bone,None)
    if kind=='bell' and number==15:
        yoke=[(102,8),(1110,8),(1188,352),(830,330),(670,252),(450,300),(112,325)]
        shell=[(630,250),(783,320),(891,558),(1135,974),(1068,1033),(878,978),(601,932),(375,956),(198,1030),(166,1002),(389,509),(468,320)]
        rim=[(166,1002),(224,1134),(428,1210),(686,1242),(979,1178),(1146,1087),(1135,974),(1097,1080),(938,1140),(697,1175),(432,1154),(249,1090)]
        clapper=[(576,935),(660,935),(688,1000),(730,1070),(689,1177),(620,1233),(573,1180),(508,1065),(535,991)]
        for label,bone,outline,depth in [('Etched blue suspension','root',yoke,.026),('Forged bell shell','prop',shell,.10),('Hollow bell rim','prop',rim,.07),('Crystal bell clapper','secondary',clapper,.04)]:
            part(label,bone,(640,260),.40/1280,depth,outline)
    elif kind=='siphon' and number==13:
        inlet=[(151,62),(417,128),(557,324),(559,427),(454,568),(264,482),(70,322),(71,223)]
        outlet=[(932,654),(1124,790),(1220,960),(1198,1125),(1093,1204),(818,1063),(666,902),(703,750)]
        part('Molten siphon enemy cuff','prop',(320,300),.38/1280,.05,inlet)
        part('Molten siphon hand cuff','secondary',(946,932),.38/1280,.05,outlet)
    else:
        height=.46 if kind in ('chalice','crown') else .42
        part('Canonical '+relic_id+' '+kind,'prop',(w*.5,h*.5),height/max(w,h),.065 if kind in ('chalice','piston') else .043)
