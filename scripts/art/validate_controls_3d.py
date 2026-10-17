from pathlib import Path
import bpy
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.open_mainfile(filepath=str(root/'assets/characters/executioner/three_d/source/executioner_human_3d.blend'))
rig=bpy.data.objects['ExecutionerRig'];controls=bpy.data.objects['Executioner_Animator_Controls']
checks=0
for action,frame in [('idle',1),('iron_strike',100),('throw',40),('block',65)]:
    rig['controls_enabled']=0.0;rig.animation_data.action=bpy.data.actions[action]
    bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
    desired={b.name:b.matrix.translation.copy() for b in rig.pose.bones}
    exec(bpy.data.texts['ALIGN_CONTROLS.py'].as_string())
    rig.update_tag();bpy.context.view_layer.update()
    print('CONTROL_INFLUENCE',rig.pose.bones['forearm.R'].constraints[-1].influence)
    for side in ('L','R'):
        for first,second,end in [('upper_arm.','forearm.','hand.'),('thigh.','shin.','foot.')]:
            joints=[rig.pose.bones[p+side].matrix.translation for p in (first,second,end)]
            for index,name in enumerate((first,second)):
                length=rig.data.bones[name+side].length
                assert abs((joints[index+1]-joints[index]).length-length)<.001,(action,'Control bone stretch',name+side)
                checks+=1
            error=(joints[2]-desired[end+side]).length
            middle_error=(joints[1]-desired[second+side]).length
            print('CONTROL_MIDDLE',action,second+side,round(middle_error,6))
            assert middle_error<.015,(action,'Control toggle changes elbow or knee',second+side,middle_error)
            checks+=1
            print('CONTROL_MATCH',action,end+side,round(error,6))
            assert error<.015,(action,'End effector mismatch',end+side,error)
            checks+=1
    ctrl=controls.pose.bones['CTRL_hand.R'];matrix=ctrl.matrix.copy();matrix.translation+=Vector((.02,0,0));ctrl.matrix=matrix
    bpy.context.view_layer.update()
    end=rig.pose.bones['forearm.R'].tail
    print('CONTROL_MOVE_ERROR',(end-matrix.translation).length)
    assert (end-matrix.translation).length<.003,'Hand control does not move the wrist'
    checks+=1
    assert (end-rig.pose.bones['hand.R'].head).length<.001,'Moving hand control detaches wrist'
    checks+=1
print('EXECUTIONER_CONTROLS_OK checks=%d actions=4 connected hands and feet, no stretch, movable hand target'%checks)
