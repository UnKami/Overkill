"""Editable Blender controls, disabled for exact baked glTF parity by default."""
import bpy
from mathutils import Vector

ALIGN_TEXT='''# Run in Blender Text Editor at the frame you want to edit.
import bpy,math
from mathutils import Vector
rig=bpy.data.objects['ExecutionerRig']
controls=bpy.data.objects['Executioner_Animator_Controls']
rig['controls_enabled']=0.0
rig.update_tag();bpy.context.view_layer.update()
matrices={b.name:b.matrix.copy() for b in rig.pose.bones}
for bone in rig.data.bones:
    controls.pose.bones['CTRL_'+bone.name].matrix=matrices[bone.name]
    bpy.context.view_layer.update()
chains=[]
for side in ('L','R'):
    for first,second,end,pole in [('upper_arm.','forearm.','hand.','ELBOW'),('thigh.','shin.','foot.','KNEE')]:
        a=matrices[first+side].translation;b=matrices[second+side].translation;c=matrices[end+side].translation
        axis=(c-a).normalized();bend=b-a-axis*(b-a).dot(axis)
        if bend.length<.001:bend=Vector((0,-1,0))
        matrix=controls.pose.bones['POLE_'+pole+'.'+side].matrix.copy()
        matrix.translation=b+bend.normalized()*.65
        controls.pose.bones['POLE_'+pole+'.'+side].matrix=matrix
        constraint=next(x for x in rig.pose.bones[second+side].constraints if x.type=='IK')
        chains.append((second+side,b,constraint))
controls.hide_set(False)
rig['controls_enabled']=1.0
rig.update_tag();bpy.context.view_layer.update()
# Calibrate pole angle against the exact current elbow/knee plane. This
# avoids a roll pop when switching from the recorded pose to editing controls.
for name,target,constraint in chains:
    best=(1e9,0.0)
    for i in range(32):
        angle=-math.pi+i*math.tau/32
        constraint.pole_angle=angle;bpy.context.view_layer.update()
        error=(rig.pose.bones[name].matrix.translation-target).length
        if error<best[0]:best=(error,angle)
    center=best[1]
    for i in range(17):
        angle=center+(i-8)*math.tau/256
        constraint.pole_angle=angle;bpy.context.view_layer.update()
        error=(rig.pose.bones[name].matrix.translation-target).length
        if error<best[0]:best=(error,angle)
    constraint.pole_angle=best[1];bpy.context.view_layer.update()
bpy.ops.object.select_all(action='DESELECT')
controls.select_set(True);bpy.context.view_layer.objects.active=controls
# Pose CTRL_hand/foot and POLE controls; CTRL_finger bones articulate grips.
'''

def add_controls(rig,bones):
    data=bpy.data.armatures.new('Executioner control skeleton')
    controls=bpy.data.objects.new('Executioner_Animator_Controls',data)
    bpy.context.scene.collection.objects.link(controls)
    bpy.ops.object.select_all(action='DESELECT')
    controls.select_set(True);bpy.context.view_layer.objects.active=controls
    bpy.ops.object.mode_set(mode='EDIT')
    for entry in bones:
        bone=data.edit_bones.new('CTRL_'+entry['name'])
        bone.head=entry['head'];bone.tail=entry['tail'];bone.align_roll(entry['roll'])
        parent=entry['parent']
        if entry['name'].startswith(('hand.','foot.')):parent='root'
        if parent:bone.parent=data.edit_bones['CTRL_'+parent]
    for side in ('L','R'):
        for name,source,offset in [('ELBOW','forearm.',(0,-.65,0)),('KNEE','shin.',(0,-.75,0))]:
            bone=data.edit_bones.new('POLE_'+name+'.'+side)
            bone.head=rig.data.bones[source+side].head_local+Vector(offset)
            bone.tail=bone.head+Vector((0,0,.12));bone.parent=data.edit_bones['CTRL_root']
    bpy.ops.object.mode_set(mode='OBJECT')
    rig['controls_enabled']=0.0
    rig.id_properties_ui('controls_enabled').update(min=0,max=1,description='Run ALIGN_CONTROLS.py before enabling. Zero preserves baked motion.')
    def driven(constraint):
        constraint.influence=0
        driver=constraint.driver_add('influence').driver
        var=driver.variables.new();var.name='enabled';var.type='SINGLE_PROP'
        var.targets[0].id=rig;var.targets[0].data_path='["controls_enabled"]'
        driver.expression='enabled'
    for entry in bones:
        name=entry['name'];pose=rig.pose.bones[name]
        con=pose.constraints.new('COPY_ROTATION' if name.startswith(('hand.','foot.')) else 'COPY_TRANSFORMS')
        con.name='Animator control';con.target=controls;con.subtarget='CTRL_'+name
        driven(con)
    for side in ('L','R'):
        for bone,target,pole in [('forearm.','hand.','ELBOW'),('shin.','foot.','KNEE')]:
            pose=rig.pose.bones[bone+side]
            con=pose.constraints.new('IK');con.name='No stretch two joint IK'
            con.target=controls;con.subtarget='CTRL_'+target+side;con.chain_count=2;con.use_stretch=False
            con.pole_target=controls;con.pole_subtarget='POLE_'+pole+'.'+side
            driven(con)
    controls.show_in_front=True;controls.hide_render=True;controls.hide_set(True)
    text=bpy.data.texts.new('ALIGN_CONTROLS.py')
    text.write(ALIGN_TEXT)
    rig['control_help']='Open ALIGN_CONTROLS.py in the Text Editor, run at the desired frame, then pose the controls. Disable controls to return to baked actions.'
