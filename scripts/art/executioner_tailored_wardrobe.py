"""Executioner garments and metalwork built in three dimensions around the skin.

Reference artwork supplies fabric/engraving swatches, never silhouette topology.
Every hood, sleeve, boot and mantle has a physical section and modeled return.
Parts share material/skin batches so ornament does not create hundreds of draws.
"""
import math
from collections import Counter
import bpy, bmesh
from mathutils import Vector, Matrix

TAU=math.tau

def ease(x):
    x=max(0,min(1,x));return x*x*(3-2*x)

def profile(knots,x):
    if x<=knots[0][0]:return knots[0][1]
    for (a,av),(b,bv) in zip(knots,knots[1:]):
        if x<=b:return av+(bv-av)*(x-a)/(b-a)
    return knots[-1][1]

def patch(cell,u,v,rect=(.20,.18,.80,.86)):
    a,b,c,d=rect
    kind=0 if cell==0 else 3 if cell==3 else 2 if cell==16 else 1
    return ((kind%2+a+(c-a)*u)/2,(1-kind//2+b+(d-b)*v)/2)

def material(name,color,metal=0,rough=.8,image=None,emission=0):
    result=bpy.data.materials.new(name);result.use_nodes=True
    shader=result.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Metallic'].default_value=metal;shader.inputs['Roughness'].default_value=rough
    if image:
        tex=result.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
        result.node_tree.links.new(tex.outputs['Color'],shader.inputs['Base Color'])
    if emission:
        shader.inputs['Emission Color'].default_value=(*color,1)
        shader.inputs['Emission Strength'].default_value=emission
    return result

def woven_cloth(name):
    # Small, low-contrast fibers leave the modeled drape to carry the shading.
    # Object coordinates have a common metre scale across hood, scarf and cape.
    result=material(name,(.018,.029,.033),rough=.91)
    nodes=result.node_tree.nodes;links=result.node_tree.links
    coords=nodes.new('ShaderNodeTexCoord')
    fibers=nodes.new('ShaderNodeTexNoise')
    fibers.inputs['Scale'].default_value=160
    fibers.inputs['Detail'].default_value=2
    fibers.inputs['Roughness'].default_value=.45
    links.new(coords.outputs['Object'],fibers.inputs['Vector'])
    color=nodes.new('ShaderNodeMixRGB')
    color.inputs[1].default_value=(.010,.023,.027,1)
    color.inputs[2].default_value=(.033,.056,.061,1)
    links.new(fibers.outputs['Fac'],color.inputs[0])
    links.new(color.outputs[0],nodes['Principled BSDF'].inputs['Base Color'])
    # Broad dye variation and fine weave occupy different scales. This gives
    # the cloth its weathered teal identity without painted light or metal.
    dye=nodes.new('ShaderNodeTexNoise');dye.inputs['Scale'].default_value=11
    dye.inputs['Detail'].default_value=3
    links.new(coords.outputs['Object'],dye.inputs['Vector'])
    patina=nodes.new('ShaderNodeMixRGB');patina.blend_type='MULTIPLY'
    patina.inputs[0].default_value=.55
    links.new(color.outputs[0],patina.inputs[1]);links.new(dye.outputs['Fac'],patina.inputs[2])
    links.new(patina.outputs[0],nodes['Principled BSDF'].inputs['Base Color'])
    warp=nodes.new('ShaderNodeTexWave');weft=nodes.new('ShaderNodeTexWave')
    for wave,direction in ((warp,'X'),(weft,'Z')):
        wave.wave_type='BANDS';wave.bands_direction=direction
        wave.inputs['Scale'].default_value=140
        links.new(coords.outputs['Object'],wave.inputs['Vector'])
    weave=nodes.new('ShaderNodeMath');weave.operation='MULTIPLY'
    links.new(warp.outputs['Fac'],weave.inputs[0]);links.new(weft.outputs['Fac'],weave.inputs[1])
    bump=nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value=.22
    bump.inputs['Distance'].default_value=.0007
    links.new(weave.outputs[0],bump.inputs['Height'])
    links.new(bump.outputs['Normal'],nodes['Principled BSDF'].inputs['Normal'])
    return result

def reference_metal(name,image):
    result=material(name,(.09,.065,.038),.42,.58,image=image)
    nodes=result.node_tree.nodes;links=result.node_tree.links
    shader=nodes['Principled BSDF'];source=shader.inputs['Base Color'].links[0].from_socket
    tint=nodes.new('ShaderNodeMixRGB');tint.blend_type='MULTIPLY';tint.inputs[0].default_value=.42
    tint.inputs[2].default_value=(.92,.70,.46,1)
    links.new(source,tint.inputs[1]);links.new(tint.outputs[0],shader.inputs['Base Color'])
    relief=nodes.new('ShaderNodeBump');relief.inputs['Strength'].default_value=.24
    relief.inputs['Distance'].default_value=.0012
    links.new(source,relief.inputs['Height']);links.new(relief.outputs['Normal'],shader.inputs['Normal'])
    return result

class Tailor:
    def __init__(self,context):
        self.context=context;self.batches={};self.neutral=context['base_pose']()
        self.rest=context['rest'];self.deformation={n:self.neutral[n]@self.rest[n].inverted() for n in self.rest}

    def bone(self,name):return self.neutral[name].translation.copy()

    def add(self,batch,points,faces,mat,weights,uv=None,smooth=True,thickness=0):
        points=[Vector(p) for p in points]
        if isinstance(weights,str):weights=[{weights:1} for p in points]
        uv=uv or [(0,0) for p in points]
        face_mats=mat if isinstance(mat,list) else [mat]*len(faces)
        if thickness:
            normals=[Vector() for p in points];counts=Counter();directions={}
            for face in faces:
                normal=(points[face[1]]-points[face[0]]).cross(points[face[2]]-points[face[0]]).normalized()
                for index in face:normals[index]+=normal
                for a,b in zip(face,face[1:]+face[:1]):
                    key=tuple(sorted((a,b)));counts[key]+=1;directions[key]=(a,b)
            n=len(points)
            points=[p+normal.normalized()*thickness*.5 for p,normal in zip(points,normals)]+[p-normal.normalized()*thickness*.5 for p,normal in zip(points,normals)]
            original=faces;faces=original+[[i+n for i in reversed(f)] for f in original]
            faces += [[b,a,a+n,b+n] for key,(a,b) in directions.items() if counts[key]==1]
            face_mats=face_mats+face_mats+[face_mats[0]]*(len(faces)-2*len(original))
            weights=weights+weights;uv=uv+uv
        row=self.batches.setdefault(batch,{'points':[],'faces':[],'weights':[],'uv':[],'materials':[],'indices':[],'smooth':[]})
        for face_mat in face_mats:
            if face_mat not in row['materials']:row['materials'].append(face_mat)
        offset=len(row['points'])
        row['points']+=points;row['weights']+=weights;row['uv']+=uv
        row['faces'] += [[offset+i for i in face] for face in faces]
        row['indices'] += [row['materials'].index(m) for m in face_mats];row['smooth'] += [smooth]*len(faces)

    def tube(self,batch,path,radius,mat,bone,segments=8):
        path=[Vector(p) for p in path];points=[]
        for i,p in enumerate(path):
            tangent=(path[min(i+1,len(path)-1)]-path[max(0,i-1)]).normalized()
            reference=Vector((0,0,1)) if abs(tangent.z)<.92 else Vector((0,1,0))
            a=tangent.cross(reference).normalized();b=tangent.cross(a).normalized()
            for j in range(segments):points.append(p+radius*(a*math.cos(TAU*j/segments)+b*math.sin(TAU*j/segments)))
        faces=[[i*segments+j,i*segments+(j+1)%segments,(i+1)*segments+(j+1)%segments,(i+1)*segments+j] for i in range(len(path)-1) for j in range(segments)]
        faces += [list(reversed(range(segments))),list(range((len(path)-1)*segments,len(path)*segments))]
        uv=[patch(0,j/segments,i/(len(path)-1),(.01,.01,.99,.99)) for i in range(len(path)) for j in range(segments)]
        binding=[entry for entry in bone for _ in range(segments)] if isinstance(bone,list) else bone
        self.add(batch,points,faces,mat,binding,uv)

    def ellipsoid(self,batch,center,scale,mat,bone,segments=24,rows=14):
        center=Vector(center);points=[]
        for j in range(rows+1):
            phi=-math.pi/2+math.pi*(.002+.996*j/rows)
            for i in range(segments):
                theta=TAU*i/segments
                points.append(center+Vector((scale[0]*math.cos(phi)*math.sin(theta),scale[1]*math.cos(phi)*math.cos(theta),scale[2]*math.sin(phi))))
        faces=[[j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i] for j in range(rows) for i in range(segments)]
        faces += [list(reversed(range(segments))),list(range(rows*segments,(rows+1)*segments))]
        self.add(batch,points,faces,mat,bone)

    def sleeve(self,batch,start,end,r0,r1,mat,bone,cell=8,flute=0,thickness=.004):
        start,end=Vector(start),Vector(end);axis=(end-start).normalized()
        forward=Vector((0,-1,0));forward=(forward-axis*forward.dot(axis)).normalized()
        across=axis.cross(forward).normalized();points=[];uv=[];segments=40;rows=8
        for j in range(rows+1):
            t=j/rows;r=r0*(1-t)+r1*t
            for i in range(segments):
                theta=TAU*i/segments
                radius=r+flute*math.cos(theta*8)*math.sin(math.pi*t)
                points.append(start.lerp(end,t)+radius*(across*math.sin(theta)+forward*.84*math.cos(theta)))
                uv.append(patch(cell,.5+.34*math.sin(theta),.08+.84*t))
        faces=[[j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i] for j in range(rows) for i in range(segments)]
        self.add(batch,points,faces,mat,bone,uv,thickness=thickness)
        return across,forward,axis

    def plate(self,batch,center,across,up,width,height,depth,mat,bone,cell=1,shape=None,trim=None):
        center=Vector(center);across=Vector(across).normalized();up=Vector(up).normalized()
        forward=across.cross(up).normalized()
        shape=shape or [(-.65,-1),(.65,-1),(1,-.4),(1,.45),(.4,1),(-.4,1),(-1,.45),(-1,-.4)]
        n=len(shape);points=[center+forward*depth];uv=[patch(cell,.5,.5)]
        # A forged inset and chamfer produce a real broad edge highlight. The
        # brass border is a sloping metal face, not a round cord laid over paint.
        for scale,bulge in ((.50,.82),(.93,.28),(1,.12)):
            for x,z in shape:
                points.append(center+across*x*width*.5*scale+up*z*height*.5*scale+forward*depth*bulge)
                uv.append(patch(cell,.5+x*.42*scale,.5+z*.42*scale))
        points += [p-forward*.006 for p in points[-n:]];uv += uv[-n:]
        faces=[[0,j+1,(j+1)%n+1] for j in range(n)]
        faces += [[1+j,1+(j+1)%n,1+n+(j+1)%n,1+n+j] for j in range(n)]
        faces += [[1+n+j,1+n+(j+1)%n,1+2*n+(j+1)%n,1+2*n+j] for j in range(n)]
        faces += [[1+2*n+j,1+2*n+(j+1)%n,1+3*n+(j+1)%n,1+3*n+j] for j in range(n)]
        faces += [list(reversed(range(1+3*n,1+4*n)))]
        face_mats=[mat]*(2*n)+[trim or mat]*n+[mat]*(n+1)
        self.add(batch,points,faces,face_mats,bone,uv,smooth=False)
        return forward

    def crystal(self,at,length,direction,mat,bone):
        at=Vector(at);axis=Vector(direction).normalized();a=axis.cross(Vector((0,1,.01))).normalized();b=axis.cross(a).normalized()
        points=[]
        for h,r in ((0,length*.22),(length*.65,length*.16)):
            for i in range(6):points.append(at+axis*h+r*(a*math.sin(TAU*i/6)+b*math.cos(TAU*i/6)))
        points.append(at+axis*length)
        faces=[[i,(i+1)%6,6+(i+1)%6,6+i] for i in range(6)]+[[6+i,6+(i+1)%6,12] for i in range(6)]+[list(reversed(range(6)))]
        self.add('Crystalline inlays',points,faces,mat,bone,smooth=False)

    def finish(self):
        for name,row in self.batches.items():
            data=bpy.data.meshes.new(name);data.from_pydata(row['points'],[],row['faces']);data.update()
            for mat in row['materials']:data.materials.append(mat)
            uv=data.uv_layers.new(name='Canonical material swatches')
            for loop in data.loops:uv.data[loop.index].uv=row['uv'][loop.vertex_index]
            for polygon,index,smooth in zip(data.polygons,row['indices'],row['smooth']):polygon.material_index=index;polygon.use_smooth=smooth
            shell=bmesh.new();shell.from_mesh(data);bmesh.ops.recalc_face_normals(shell,faces=list(shell.faces));shell.to_mesh(data);shell.free()
            obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj)
            weights={}
            for v,entries in zip(data.vertices,row['weights']):
                total=sum(entries.values());assert total>0
                transform=Matrix(((0,0,0,0),)*4)
                for bone,w in entries.items():
                    w/=total;transform+=self.deformation[bone]*w
                    weights.setdefault(bone,[]).append(([v.index],w))
                v.co=transform.inverted()@v.co
            self.context['bind'](obj,weights,None)
            for polygon,smooth in zip(data.polygons,row['smooth']):polygon.use_smooth=smooth
            obj['construction']='Tailored sectional geometry, no silhouette extrusion'

def dress(context):
    rig=context['rig'];body=context['human'];models=context['model_objects']
    image=bpy.data.images.load(str(context['OUT']/'materials/executioner_surface_atlas_v3.png'));image.pack()
    for obj in list(models):
        if obj!=body:bpy.data.objects.remove(obj,do_unlink=True)
    models[:]=[body];tailor=Tailor(context)
    fabric=woven_cloth('Woven indigo garment')
    hood_cloth=woven_cloth('Hood woven navy')
    suit=material('Supple charcoal leather undersuit',(.009,.014,.020),rough=.91,image=image)
    suit_shader=suit.node_tree.nodes['Principled BSDF']
    suit_source=suit_shader.inputs['Base Color'].links[0].from_socket
    suit_tint=suit.node_tree.nodes.new('ShaderNodeMixRGB');suit_tint.blend_type='MULTIPLY'
    suit_tint.inputs[0].default_value=1;suit_tint.inputs[2].default_value=(.64,.39,.22,1)
    suit.node_tree.links.new(suit_source,suit_tint.inputs[1])
    suit.node_tree.links.new(suit_tint.outputs[0],suit_shader.inputs['Base Color'])
    steel=reference_metal('Reference etched aged armor',image)
    plain_steel=material('Forged slate rear plates',(.024,.037,.055),.58,.63,image=image)
    bronze=material('Antique warm bronze',(.27,.145,.060),.68,.54)
    gold=material('Worn brass edges',(.36,.225,.095),.72,.48)
    leather=material('Oiled blue black leather',(.012,.016,.023),rough=.81)
    boot_leather=material('Scuffed charcoal boot leather',(.012,.016,.023),rough=.81,image=image)
    coat=reference_metal('Reference engraved coat panels',image)
    coat.node_tree.nodes['Principled BSDF'].inputs['Metallic'].default_value=.24
    coat.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.79
    dark=material('Recessed faceless obsidian',(.003,.005,.008),.42,.42)
    cyan=material('Inlaid cyan fracture',(.007,.22,.34),.22,.32,emission=.65)
    ember=material('Inlaid amber fracture',(.38,.073,.006),.25,.35,emission=.5)
    body.data.materials[0]=suit
    context['void'].node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value=0
    context['void'].surface_render_method='DITHERED'
    for loop in body.data.uv_layers.active.data:loop.uv=patch(16,float(loop.uv.x),float(loop.uv.y),(.04,.04,.96,.96))
    for face in body.data.polygons:
        face.material_index=1 if sum(body.data.vertices[i].co.z for i in face.vertices)/len(face.vertices)>1.67 else 0
    rig['wardrobe_version']=9

    # A genuinely open hood: section rings wrap a skull, taper into a forward
    # brow and have a sewn return at the aperture rather than painted side walls.
    rows=24;cols=64;points=[];uv=[];weights=[]
    for j in range(rows+1):
        t=j/rows;z=1.625+.360*t
        radius=.150*math.sin((.18+.81*t)*math.pi)**.48
        radius*=1-.90*ease((t-.90)/.10)
        gap=.67*math.sin(math.pi*t)**.55+.12
        for i in range(cols+1):
            u=i/cols;a=gap+(TAU-2*gap)*u
            fold=(.010*math.sin(5*a+t*3)+.003*math.sin(11*a-t*5))*math.sin(math.pi*t)
            lead=-.028-.06*ease((t-.65)/.35)
            point=Vector((math.sin(a)*(radius+fold),-math.cos(a)*(radius*1.13+fold)+lead,z))
            point.y-=.150*math.exp(-((t-.80)/.18)**2)*max(0,math.cos(a))
            point.z+=.016*math.cos(a*2+.4)*math.sin(math.pi*t)
            points.append(point);uv.append(patch(0,u,t,(.01,.01,.99,.99)))
            head=ease((z-1.64)/.095);weights.append({'head':head,'spine_upper':1-head} if 0<head<1 else {'head' if head else 'spine_upper':1})
    faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(rows) for i in range(cols)]
    faces.append(list(range(rows*(cols+1),(rows+1)*(cols+1))))
    tailor.add('Canonical deep folded hood and scarf',points,faces,hood_cloth,weights,uv,thickness=.007)
    for edge in (0,cols):
        path=[points[j*(cols+1)+edge] for j in range(3,rows+1)]
        edge_weights=[weights[j*(cols+1)+edge] for j in range(3,rows+1)]
        tailor.tube('Hood tailored aperture seam',path,.0045,fabric,edge_weights)
    # Faceless mask, metallic circuitwork seated on its front curvature.
    widths=[(0,.025),(.16,.071),(.36,.101),(.67,.112),(.86,.090),(1,.037)]
    depths=[(0,.037),(.22,.076),(.65,.092),(.88,.079),(1,.034)]
    points=[];cols=48;rows=28
    for j in range(rows+1):
        t=j/rows;z=1.675+.285*t
        for i in range(cols):
            a=TAU*i/cols
            points.append((profile(widths,t)*math.sin(a),-.040-profile(depths,t)*math.cos(a),z))
    faces=[[j*cols+i,j*cols+(i+1)%cols,(j+1)*cols+(i+1)%cols,(j+1)*cols+i] for j in range(rows) for i in range(cols)]
    faces += [list(reversed(range(cols))),list(range(rows*cols,(rows+1)*cols))]
    tailor.add('Recessed faceless mask',points,faces,dark,'head',smooth=True)
    def mask_at(u,t):
        return Vector((u*profile(widths,t),-.040-profile(depths,t)*math.sqrt(1-u*u)-.002,1.675+.285*t))
    fractures=[[(.05,.20),(-.11,.34),(.03,.45),(-.19,.58),(-.05,.72),(.10,.85)],
               [(-.63,.36),(-.31,.40),(-.11,.34)],[(.03,.45),(.33,.52),(.44,.70)],
               [(-.19,.58),(-.51,.68),(-.64,.82)],[(.33,.52),(.63,.47),(.77,.61)],
               [(-.05,.72),(.27,.76),(.49,.88)],[(.05,.20),(.43,.29),(.62,.37)],
               [(-.51,.68),(-.67,.53),(-.79,.48)]]
    for k,path in enumerate(fractures):
        tailor.tube('Mask circuit tracery',[mask_at(u,t) for u,t in path],.00115,gold if k%3 else ember,'head',6)
    # Fine splintered metal veins echo the reference's shattered faceless
    # surface. They follow the curved mask rather than suggesting facial parts.
    for sign in (-1,1):
        for k in range(7):
            t=.26+k*.085
            u=sign*(.24+.075*(k%3))
            path=[(u,t),(u+sign*.15,t+.035),(u+sign*.23,t+.13)]
            tailor.tube('Mask circuit tracery',[mask_at(x,z) for x,z in path],.00065,bronze,'head',5)
    # A continuous draped cowl, with broad folded cloth rather than separate
    # circular cords. Its upper edge returns into the hood; the lower front
    # hangs over the chest without opening seams between its folds.
    points=[];uv=[];rows=18;cols=64
    for j in range(rows+1):
        t=j/rows
        for i in range(cols):
            a=TAU*i/cols
            fold=.013*math.cos(t*math.pi*6+a*.7)*math.sin(math.pi*t)
            rx=.215-.055*t+fold;ry=.176-.050*t+fold
            z=1.55+.125*t-.069*max(0,math.cos(a))*math.sin(math.pi*t)+.012*math.sin(a*3)*math.sin(math.pi*t)
            points.append((math.sin(a)*rx,-math.cos(a)*ry-.008,z))
            uv.append(patch(0,i/cols,t,(.03,.03,.97,.97)))
    faces=[[j*cols+i,j*cols+(i+1)%cols,(j+1)*cols+(i+1)%cols,(j+1)*cols+i] for j in range(rows) for i in range(cols)]
    tailor.add('Wrapped layered scarf',points,faces,fabric,'spine_upper',uv,thickness=.005)

    # Mantle is a draped horseshoe around the shoulders and back. The six cloth
    # joints blend by lateral position; no abrupt nearest-column skin transfer.
    rows=34;cols=56;points=[];weights=[];uv=[]
    for j in range(rows+1):
        t=j/rows
        for i in range(cols+1):
            u=i/cols;a=1.28+(TAU-2.56)*u
            spread=.13+.135*ease(t/.18)+.070*t
            # Gathered at the shoulder seam, opening into long gravity folds.
            # The rear-facing displacement keeps the side opening off the arms
            # instead of inflating the whole horseshoe with radial ripples.
            fold_width=.008+.055*ease(t/.65)
            fold_phase=math.tau*(4*u+.10*math.sin(math.pi*t))
            fold=fold_width*math.cos(fold_phase)*math.sin(math.pi*u)**.6
            x=spread*math.sin(a)
            y=-(.14+.12*t)*math.cos(a)+.045+fold
            # A shallow shoulder drape releases below the clasp; it is not a
            # flat vertical curtain attached to the neck.
            y+=.022*math.sin(math.pi*min(1,t/.32))*math.sin(math.pi*u)
            hem=[(0,.09),(.08,.012),(.12,.07),(.16,-.04),(.22,.015),(.27,-.11),(.32,.012),(.42,.018),(.47,.075),(.53,.015),(.60,-.08),(.65,.02),(.75,.013),(.80,.10),(.84,-.035),(.90,.018),(1,.08)]
            notch=profile(hem,u)*ease((t-.88)/.12)
            z=1.565-1.015*t+notch-.035*math.cos(a)*ease(t/.25)
            points.append((x,y,z));uv.append(patch(3,u,t,(.04,.04,.96,.96)))
            column=max(0,min(2,(x/.37+.5)*2));left=min(1,int(column));blend=column-left
            low=ease((t-.22)/.63);entry={}
            for c,w in ((left,1-blend),(left+1,blend)):
                for n,amount in ((f'cloak_upper_{c}',w*(1-low)),(f'cloak_lower_{c}',w*low)):
                    if amount>.000001:entry[n]=amount
            weights.append(entry)
    faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(rows) for i in range(cols)]
    tailor.add('Wrapped torn cloth mantle',points,faces,fabric,weights,uv,thickness=.004)
    # Sewn returns follow exactly the same skin weights as the cloth beneath.
    for indices in ([j*(cols+1) for j in range(rows+1)],
                    [j*(cols+1)+cols for j in range(rows+1)],
                    [rows*(cols+1)+i for i in range(cols+1)]):
        tailor.tube('Wrapped torn cloth mantle',[points[k] for k in indices],
                    .0023,fabric,[weights[k] for k in indices],6)

    # Fitted steel cuirass with real side/back return and a floating front crest.
    profiles=[(1.19,.18,.16),(1.28,.215,.173),(1.40,.245,.186),(1.49,.245,.17),(1.54,.195,.133)]
    points=[];uv=[];weights=[];cols=64
    for z,rx,ry in profiles:
        for i in range(cols):
            a=TAU*i/cols;r=.003*math.cos(a*10)
            points.append((math.sin(a)*(rx+r),-math.cos(a)*(ry+r),z))
            uv.append(patch(1,.5+.49*math.sin(a),(z-1.19)/.35,(.02,.02,.98,.98)))
            upper=ease((z-1.21)/.24);weights.append({'spine_upper':upper,'spine_mid':1-upper})
    faces=[[j*cols+i,j*cols+(i+1)%cols,(j+1)*cols+(i+1)%cols,(j+1)*cols+i] for j in range(len(profiles)-1) for i in range(cols)]
    # Use distinct front engraving and metal rear faces, on the same solid shell.
    face_mats=[steel if math.cos(TAU*(i+.5)/cols)>.2 else plain_steel for j in range(len(profiles)-1) for i in range(cols)]
    tailor.add('Fitted wrapped cuirass',points,faces,face_mats,weights,uv,thickness=.004)
    # Sweeping overlapping breastplates carry the reference's asymmetric
    # silhouette. Their section follows the cuirass, including the side return.
    def breast_surface(x,z,offset=0):
        rx=profile([(p[0],p[1]) for p in profiles],z)
        ry=profile([(p[0],p[2]) for p in profiles],z)
        return Vector((x,-ry*math.sqrt(max(.025,1-(x/rx)**2))-.012-offset,z))
    def chest_relief_surface(x,z):
        # Find the outermost overlapping plate at this ornament point. Fixed
        # offsets put the scrolls beneath the plate crown and hid them in game.
        offset=0
        for layer in range(3):
            t=(1.50-layer*.055+.72*(x+.185)-z)/(.31+.72*.305)
            if not 0<=t<=1:continue
            cx=-.185+.305*t;width=.040+.027*math.sin(math.pi*t)
            u=.5+(x-cx)/width
            if 0<=u<=1:offset=max(offset,.004*layer+.008*math.sin(math.pi*u)+.002)
        return breast_surface(x,z,offset+.0035)
    # The illustration's defining longcoat begins at a turned collar, rather
    # than at the waist. Tapered leather lapels follow the actual cuirass and
    # continue the coat's vertical silhouette over the diagonal armor lames.
    for sign in (-1,1):
        lapel=[];lapel_uv=[];lapel_skin=[];rows=28;cols=8
        for j in range(rows+1):
            t=j/rows;z=1.52-.31*t
            cx=sign*(.160-.115*t);width=.058*(1-.50*t)
            for i in range(cols+1):
                u=i/cols;x=cx+(u-.5)*width
                p=breast_surface(x,z,.028+.012*math.sin(math.pi*u))
                lapel.append(p);lapel_uv.append(patch(1,u,t,(.48,.05,.66,.95)))
                upper=ease((z-1.21)/.24);lapel_skin.append({'spine_upper':upper,'spine_mid':1-upper})
        lapel_faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(rows) for i in range(cols)]
        tailor.add('Folded split coat tassets',lapel,lapel_faces,coat,lapel_skin,lapel_uv,thickness=.004)
        for edge in (0,cols):
            indices=[j*(cols+1)+edge for j in range(rows+1)]
            tailor.tube('Raised bronze piping',[lapel[k] for k in indices],.0021,bronze,[lapel_skin[k] for k in indices],6)
    for layer in range(3):
        points=[];uv=[];weights=[];rows=24;cols=12
        for j in range(rows+1):
            t=j/rows
            cx=-.185+.305*t;cz=1.50-.31*t-layer*.055
            width=.040+.027*math.sin(math.pi*t)
            for i in range(cols+1):
                u=i/cols;x=cx+(u-.5)*width;z=cz+(u-.5)*width*.72
                points.append(breast_surface(x,z,.004*layer+.008*math.sin(math.pi*u)))
                uv.append(patch(1,u,t,(.02+.14*layer,.04,.17+.14*layer,.96)))
                upper=ease((z-1.21)/.24);weights.append({'spine_upper':upper,'spine_mid':1-upper})
        faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(rows) for i in range(cols)]
        tailor.add('Sweeping overlapping breastplates',points,faces,steel,weights,uv,thickness=.004)
        for edge in (0,cols):
            path=[points[j*(cols+1)+edge] for j in range(rows+1)]
            skin=[weights[j*(cols+1)+edge] for j in range(rows+1)]
            tailor.tube('Raised bronze piping',path,.0024,gold,skin)
    # Engraved spirals are physical relief seated on the near breastplate.
    for cx,cz,rad in [(-.13,1.43,.035),(-.10,1.345,.041),(-.052,1.265,.030)]:
        path=[];skin=[]
        for i in range(65):
            t=i/64;a=.5+TAU*1.45*t;r=rad*(1-.84*t)
            x=cx+r*math.cos(a);z=cz+r*math.sin(a)
            path.append(chest_relief_surface(x,z))
            upper=ease((z-1.21)/.24);skin.append({'spine_upper':upper,'spine_mid':1-upper})
        tailor.tube('Chest embossed scrollwork',path,.0022,bronze,skin,8)
    for sign in (-1,1):
        for k in range(3):
            path=[chest_relief_surface(sign*(.055+.045*i/14),1.40+k*.023+.03*math.sin(math.pi*i/14)) for i in range(15)]
            skin=[{'spine_upper':ease((p.z-1.21)/.24),'spine_mid':1-ease((p.z-1.21)/.24)} for p in path]
            tailor.tube('Chest embossed scrollwork',path,.0023,gold,skin,8)
    for k,(z,rx,ry) in enumerate(((1.205,.183,.126),(1.136,.179,.122),(1.072,.187,.131))):
        points=[];uv=[];cols=48
        for j in range(3):
            for i in range(cols+1):
                a=-1.62+3.24*i/cols
                points.append((math.sin(a)*rx,-math.cos(a)*ry,z+(j-1)*.035))
                uv.append(patch(2,i/cols,j/2,(.28,.36,.72,.74)))
        faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(2) for i in range(cols)]
        bone='spine_mid' if k==0 else 'spine_lower'
        tailor.add('Overlapping abdominal lames',points,faces,steel,bone,uv,thickness=.005)
        tailor.tube('Raised bronze piping',points[:cols+1],.003,gold,bone)
    tailor.sleeve('Fitted waist harness',(0,0,1.012),(0,0,1.058),.194,.194,leather,'pelvis',flute=0)
    tailor.plate('Raised heraldic metalwork',(0,-.17,1.035),(1,0,0),(0,0,1),.085,.07,.012,bronze,'pelvis',trim=gold)

    # Two shaped tassets wrap each hip and descend in folds. They leave a
    # central opening so a bent leg cannot drag a full rectangular apron.
    for side,sign in (('L',1),('R',-1)):
        rows=22;cols=18;points=[];uv=[];weights=[]
        for j in range(rows+1):
            t=j/rows
            for i in range(cols+1):
                u=i/cols;a=sign*(.10+.20*t+1.31*u)
                r=.19+.060*math.sin(t*math.pi*.8)+.009*math.sin(5*u*math.pi)*(t+.2)
                x=math.sin(a)*r;y=-math.cos(a)*(.155+.034*t)
                z=1.055-.46*t+.080*math.cos(math.pi*u)*t*t
                points.append((x,y,z));uv.append(patch(1,u,t,(.06,.05,.94,.95)))
                low=ease((t-.1)/.65);weights.append({'pelvis':1-low,'skirt.'+side:low})
        faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(rows) for i in range(cols)]
        tailor.add('Folded split coat tassets',points,faces,coat,weights,uv,thickness=.005)
        # The long reference coat has finished curved borders, not small
        # floating hip badges over a blue rectangular apron.
        hem_indices=[rows*(cols+1)+i for i in range(cols+1)]
        tailor.tube('Raised bronze piping',[points[k] for k in hem_indices],.0026,bronze,[weights[k] for k in hem_indices],8)
        for edge in (0,cols):
            path=[Vector(points[j*(cols+1)+edge])+Vector((0,-.002,0)) for j in range(rows+1)]
            skin=[weights[j*(cols+1)+edge] for j in range(rows+1)]
            tailor.tube('Raised bronze piping',path,.0018,bronze,skin,6)
        tailor.plate('Suspended etched hip scales',(sign*.166,-.145,.88),(1,0,0),(0,0,1),.11,.19,.010,steel,'skirt.'+side,2,trim=gold)

    # Physical limb sections, separate plates and joints. Crystal asymmetry
    # follows the established near/right cyan and far/left amber artwork.
    for side,sign,cell,glow in (('R',-1,7,cyan),('L',1,4,ember)):
        shoulder=tailor.bone('upper_arm.'+side);elbow=tailor.bone('forearm.'+side);wrist=tailor.bone('hand.'+side)
        hip=tailor.bone('thigh.'+side);knee=tailor.bone('shin.'+side);ankle=tailor.bone('foot.'+side)
        up=(shoulder-elbow).normalized();across=Vector((1,0,0));across=(across-up*across.dot(up)).normalized()
        for k in range(3):
            center=shoulder+Vector((sign*(.019+.018*k),-.042,-.031*k))
            shape=[(-.7,-.8),(.7,-.8),(1,.25),(.54,1.15),(-.5,.75),(-1,.0)]
            tailor.plate('Layered articulated pauldrons',center,across,Vector((0,0,1)),(.262 if side=='R' else .214)-.018*k,.16 if side=='R' else .135,.060-.009*k,steel,'clavicle.'+side,cell,shape,gold)
        tailor.sleeve('Leather arm harness',shoulder.lerp(elbow,.28),shoulder.lerp(elbow,.85),.078,.065,suit,'upper_arm.'+side,16)
        a,b,axis=tailor.sleeve('Fluted steel vambraces',elbow.lerp(wrist,.14),elbow.lerp(wrist,.84),.082,.061,steel,'forearm.'+side,cell+1,.006)
        for f in (.16,.81):
            p=elbow.lerp(wrist,f)
            tailor.sleeve('Bronze joint cuffs',p-axis*.008,p+axis*.008,.084 if f<.5 else .063,.084 if f<.5 else .063,gold,'forearm.'+side)
        palm=tailor.bone('hand.'+side);finger=tailor.bone('finger3-1.'+side)
        frame=tailor.neutral['hand.'+side];hand_up=frame.col[1].xyz.normalized();hand_across=frame.col[0].xyz.normalized()
        center=(palm+finger)*.5+frame.col[2].xyz.normalized()*.012
        tailor.plate('Articulated palm and finger armor',center,hand_across,hand_up,.085,.095,.012,bronze,'hand.'+side,cell+2,trim=gold)
        for f in range(2,6):
            for segment in (1,2):
                name=f'finger{f}-{segment}.{side}';pose=tailor.neutral[name];at=pose.translation+pose.col[2].xyz.normalized()*.010
                tailor.ellipsoid('Articulated palm and finger armor',at,(.012,.014,.009),bronze,name,12,8)
        # Contoured poleyn and greave, with boots enclosing the actual foot.
        leg_up=(knee-ankle).normalized();leg_across=Vector((1,0,0));leg_across=(leg_across-leg_up*leg_across.dot(leg_up)).normalized()
        tailor.plate('Contoured leg armor',hip.lerp(knee,.38)+Vector((0,-.085,0)),leg_across,leg_up,.15,.275,.022,steel,'thigh.'+side,13 if side=='R' else 10,trim=gold)
        tailor.plate('Contoured leg armor',knee+Vector((0,-.055,.008)),leg_across,leg_up,.13,.15,.018,steel,'shin.'+side,14 if side=='R' else 11,trim=gold)
        a,b,axis=tailor.sleeve('Fluted steel greaves',knee.lerp(ankle,.18),knee.lerp(ankle,.96),.076,.060,steel,'shin.'+side,14 if side=='R' else 11,.005)
        for f in (.20,.79):
            at=knee.lerp(ankle,f)
            tailor.sleeve('Bronze joint cuffs',at-axis*.01,at+axis*.01,.078 if f<.5 else .066,.078 if f<.5 else .066,gold,'shin.'+side)
        # D-shaped sections fitted around the measured anatomical foot. The
        # outsole has physical thickness; it does not clamp half an ellipse
        # onto coincident vertices or float 18mm above the support plane.
        points=[];uv=[];cols=32
        sections=[(.079,.034,.080),(.040,.045,.104),(-.020,.052,.121),(-.065,.064,.112),(-.125,.069,.086),(-.18,.065,.062),(-.216,.048,.043),(-.239,.015,.020)]
        shoe_x=ankle.x+sign*.007
        sole=-.002
        for k,(y,width,height) in enumerate(sections):
            for i in range(cols):
                if i<=28:
                    a=math.pi*i/28
                    x=width*math.cos(a);z=sole+.006+(height-sole-.006)*math.sin(a)
                else:
                    x=width*[-.96,0,.96][i-29];z=sole
                points.append((shoe_x+x,ankle.y+y,z))
                uv.append(patch(16,i/cols,k/(len(sections)-1),(.04,.04,.96,.96)))
        faces=[[j*cols+i,j*cols+(i+1)%cols,(j+1)*cols+(i+1)%cols,(j+1)*cols+i] for j in range(len(sections)-1) for i in range(cols)]
        faces += [list(reversed(range(cols))),list(range((len(sections)-1)*cols,len(sections)*cols))]
        tailor.add('Rounded strapped armored boots',points,faces,boot_leather,'foot.'+side,uv)
        # Three overlapping sabatons follow the actual upper shoe sections;
        # their normals face up, their edges sit against the leather.
        width_profile=sorted((y,w) for y,w,h in sections)
        height_profile=sorted((y,h) for y,w,h in sections)
        for k in range(3):
            points=[];uv=[];cols=24;rows=4
            for j in range(rows+1):
                y=-.220+.050*k+.055*j/rows
                width=profile(width_profile,y);height=profile(height_profile,y)
                for i in range(cols+1):
                    a=.16+(math.pi-.32)*i/cols
                    points.append((shoe_x+width*math.cos(a),ankle.y+y,sole+.006+(height-sole-.006)*math.sin(a)+.004))
                    uv.append(patch(15 if side=='R' else 12,i/cols,j/rows))
            faces=[[j*(cols+1)+i,j*(cols+1)+i+1,(j+1)*(cols+1)+i+1,(j+1)*(cols+1)+i] for j in range(rows) for i in range(cols)]
            tailor.add('Contoured boot sabatons',points,faces,steel,'foot.'+side,uv,thickness=.003)
            tailor.tube('Raised bronze piping',points[:cols+1],.0023,gold,'foot.'+side)
        for k in range(3):
            y=-.042-.045*k;width=profile(width_profile,y);height=profile(height_profile,y)
            path=[(shoe_x+(width+.002)*math.cos(math.pi*i/20),ankle.y+y,sole+.006+(height-sole-.006)*math.sin(math.pi*i/20)+.006) for i in range(21)]
            tailor.tube('Boot woven straps',path,.005,leather,'foot.'+side,8)
        for k in range(7):
            at=shoulder+Vector((sign*(.051+.013*(k%3)),-.069,-.026+.024*(k//3)))
            tailor.crystal(at,(.041 if side=='R' else .029)+.014*(k%3),(sign*.6,-.6,1),glow,'clavicle.'+side)
        for k in range(5):
            at=elbow.lerp(wrist,.25+k*.11)+Vector((sign*.028,-.057,0))
            tailor.crystal(at,.029+.012*(k%2),(sign*.4,-1,.2),glow,'forearm.'+side)
        for k in range(4):
            at=knee.lerp(ankle,.40+k*.10)+Vector((sign*.037,-.054,0))
            tailor.crystal(at,.020+.007*(k%2),(sign*.55,-1,.35),cyan,'shin.'+side)
        # Raised filigree on the curved sleeve keeps detail readable from the
        # side as well as the original three-quarter illustration direction.
        for k in range(3):
            path=[]
            for i in range(22):
                t=.22+.54*i/21;a=-.7+.70*k+.18*math.sin(t*TAU*2+k)
                center=elbow.lerp(wrist,t);rad=.083*(1-t)+.061*t
                direction=Vector((math.sin(a),-math.cos(a),0))
                path.append(center+direction*(rad+.004))
            tailor.tube('Sleeve embossed filigree',path,.0018,bronze,'forearm.'+side,6)
    tailor.finish()
    print('TAILORED_WARDROBE_BUILT batches=%d sectional cloth, armor, boots and articulated fingers'%len(tailor.batches))
    return len(models)
