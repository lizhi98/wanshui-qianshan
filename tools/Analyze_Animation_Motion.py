from pathlib import Path
import json,numpy as np,sys,collections,math
ROOT=Path(__file__).resolve().parent.parent
LIMITS=json.loads((ROOT/'ANIMATION_ACCEPTANCE_V413.json').read_text(encoding='utf8'))
def analyze(path):
 r=json.loads(Path(path).read_text(encoding='utf8'));rows=r['samples'];out=[];checks=[];stats={};groups=collections.defaultdict(list)
 for x in rows:groups[x['id']].append(x)
 phase_start={p['phase']:p['time'] for p in r['phases']}
 def check(name,value,limit,ok):checks.append({'test':name,'value':value,'limit':limit,'passed':bool(ok)})
 def bad(x,kind,value,limit):out.append({'id':x['id'],'time':x['time'],'phase':x['phase'],'position':x['position'],'mode':x['mode'],'pose':x['pose'],'kind':kind,'value':float(value),'limit':float(limit),'source':'game/memorial/player.gd' if x['id']=='Player' else 'game/memorial/npc.gd','pose_source':'game/memorial/visual.gd + contact_ik.gd'})
 for actor,a in groups.items():
  stable=[x for x in a if x['time']>LIMITS['spawn_settle_seconds']]
  gap=max(abs(x['ground_gap']) for x in stable);check(actor+' root ground gap',gap,LIMITS['nonjump_root_ground_gap'],gap<=LIMITS['nonjump_root_ground_gap'])
  for x in stable:
   if abs(x['ground_gap'])>LIMITS['nonjump_root_ground_gap']:bad(x,'root_ground_gap',abs(x['ground_gap']),LIMITS['nonjump_root_ground_gap'])
  maxdy=maxyaw=maxhip=maxhand=0.0;slipmax=0.0;stance_start={};last_route=a[0]['route'];switches=[]
  for i in range(1,len(a)):
   x,y=a[i],a[i-1];dt=max(.00001,x['time']-y['time'])
   if x['time']<=2:continue
   dy=abs(x['position'][1]-y['position'][1])/(dt*60);yaw=abs(math.atan2(math.sin(x['yaw']-y['yaw']),math.cos(x['yaw']-y['yaw'])))/dt
   hip=abs(x['bones']['pelvis'][1]-y['bones']['pelvis'][1])/(dt*60);hand=max(np.linalg.norm(np.array(x['bones'][n])-y['bones'][n]) for n in ['hand_l','hand_r'])/(dt*60)
   maxdy=max(maxdy,dy);maxyaw=max(maxyaw,yaw);maxhip=max(maxhip,hip);maxhand=max(maxhand,hand)
   for kind,value,key in [('root_vertical_delta',dy,'vertical_speed_per_frame_at_60hz'),('yaw_rate',yaw,'yaw_radians_per_second'),('pelvis_delta',hip,'pelvis_delta_per_frame_at_60hz'),('hand_delta',hand,'hand_delta_per_frame_at_60hz')]:
    if value>LIMITS[key]+1e-5:bad(x,kind,value,LIMITS[key])
   for side in ['l','r']:
    n='foot_'+side;c=x.get('contacts',{}).get(side,{})
    if c.get('planted') and n in x['feet']:
     p=np.array(x['feet'][n]['position'])[[0,2]]
     if side not in stance_start or stance_start[side][0]!=c.get("plant_id",0):stance_start[side]=(c.get("plant_id",0),p)
     slipmax=max(slipmax,float(np.linalg.norm(p-stance_start[side][1])))
    else:stance_start.pop(side,None)
   if x['route']!=last_route:switches.append(x['time']);last_route=x['route']
  for name,value,key in [('root vertical delta at 60Hz',maxdy,'vertical_speed_per_frame_at_60hz'),('yaw rate',maxyaw,'yaw_radians_per_second'),('pelvis delta at 60Hz',maxhip,'pelvis_delta_per_frame_at_60hz'),('hand delta at 60Hz',maxhand,'hand_delta_per_frame_at_60hz'),('support-foot drift',slipmax,'stance_horizontal_drift_per_plant')]:check(actor+' '+name,value,LIMITS[key],value<=LIMITS[key]+1e-5)
  penetration=max([max(0,-f['sole_gap']) for x in stable for f in x['feet'].values()] or [0]);check(actor+' sole penetration',penetration,LIMITS['sole_penetration'],penetration<=LIMITS['sole_penetration'])
  for x in stable:
   for side,f in x['feet'].items():
    if -f['sole_gap']>LIMITS['sole_penetration']:bad(x,side+'_penetration',-f['sole_gap'],LIMITS['sole_penetration'])
  stopped=[x for x in stable if x['phase'] in ['Idle','IdleAfterSalute','IdleAfterClear','Stop','ColumnStop','StopAfterCarry'] and x['time']-phase_start[x['phase']]>1]
  if stopped:
   footgap=max(abs(f['sole_gap']) for x in stopped for f in x['feet'].values());check(actor+' stationary foot gap',footgap,LIMITS['stationary_sole_gap'],footgap<=LIMITS['stationary_sole_gap'])
  count=max([sum(t<=s<t+1 for s in switches) for t in switches] or [0]);check(actor+' path switches per second',count,LIMITS['target_switches_per_second'],count<=LIMITS['target_switches_per_second'])
  for phase in ['Walk','Run','DropWalk','WalkAfterSalute','WalkAfterAim','WalkAfterInteraction','WalkAfterClear']:
   b=[x for x in stable if x['phase']==phase and x['time']-phase_start[phase]>.8]
   if len(b)<60:continue
   for foot,hand in [('l','r'),('r','l')]:
    u=np.array([x['bones']['foot_'+foot][2] for x in b]);v=np.array([x['bones']['hand_'+hand][2] for x in b]);corr=float(np.corrcoef(u,v)[0,1])
    check(actor+' '+phase+' opposite '+foot+hand,corr,LIMITS['cross_limb_correlation_min'],corr>=LIMITS['cross_limb_correlation_min'])
    same=float(np.corrcoef(u,np.array([x['bones']['hand_'+foot][2] for x in b]))[0,1]);check(actor+' '+phase+' same-side '+foot,same,LIMITS['same_limb_correlation_max'],same<=LIMITS['same_limb_correlation_max'])
  for phase in ['Idle','IdleAfterSalute','IdleAfterClear']:
   rest=[x for x in stable if x['phase']==phase and x['time']-phase_start[phase]>1]
   if not rest:continue
   height=max(x['bones'][n][1] for x in rest for n in ['hand_l','hand_r']);span=max(abs(x['bones']['hand_l'][0]-x['bones']['hand_r'][0]) for x in rest)
   check(actor+' '+phase+' relaxed hand height',height,1.15,height<1.15);check(actor+' '+phase+' no rest-pose arm span',span,1.0,span<1.0)
  if r['case']=='D':
   b=[x for x in stable if x['time']>2];v=np.array([x['bones']['Head'] for x in b]);frozen=float(np.max(np.linalg.norm(v-v[0],axis=1)));check(actor+' seated head position fixed',frozen,.001,frozen<.001)
  if r['case']=='B':check(actor+' finishes all route waypoints',a[-1]['route'],a[-1].get('route_count',6),a[-1]['route']>=a[-1].get('route_count',6))
  stats[actor]={'max_root_gap' :gap,'max_vertical_delta_at60hz':maxdy,'max_yaw_rate':maxyaw,'max_pelvis_delta_at60hz':maxhip,'max_hand_delta_at60hz':maxhand,'max_stance_drift':slipmax,'max_sole_penetration':penetration}
  speeds=[math.hypot(x['velocity'][0],x['velocity'][2]) for x in stable]
  stats[actor]['physical_horizontal_speed_range']=[min(speeds),max(speeds)]
  rates=[x['animation_rate'] for x in stable]
  stats[actor]['animation_time_scale_range']=[min(rates),max(rates)]
  stats[actor]['animation_owner_transitions']=[{'time':x['time'],'owner':x['owner'],'pose':x['pose']} for i,x in enumerate(a) if i==0 or x['owner']!=a[i-1]['owner'] or x['pose']!=a[i-1]['pose']]
 if len(groups)>1:
  by_time=collections.defaultdict(list)
  for x in rows:
   if x['time']>2:by_time[x['time']].append(x)
  distance=100.0;worst=None
  for t,a in by_time.items():
   for i in range(len(a)):
    for j in range(i):
     if abs(a[i]['position'][1]-a[j]['position'][1])>.8:continue
     d=float(np.linalg.norm(np.array(a[i]['position'])[[0,2]]-np.array(a[j]['position'])[[0,2]]))
     if d<distance:distance=d;worst={'time':t,'ids':[a[i]['id'],a[j]['id']]}
  check('NPC minimum horizontal body clearance',distance,LIMITS['npc_min_horizontal_clearance'],distance>=LIMITS['npc_min_horizontal_clearance']);stats['closest_pair']=worst
 result={'case':r['case'],'fixture':True,'movie':r['movie'],'limits':LIMITS,'checks':checks,'passes':sum(x['passed'] for x in checks),'failures':sum(not x['passed'] for x in checks),'stats':stats,'outliers':out}
 target=Path(path).with_name('metrics.json');target.write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8');print(r['case'],'PASS',result['passes'],'FAIL',result['failures'],'outliers',len(out));[print('FAIL',x['test'],x['value'],x['limit']) for x in checks if not x['passed']];return result
if __name__=='__main__':
 paths=[Path(x) for x in sys.argv[1:]] or list((ROOT/'test_evidence/v413').glob('*/motion.json'))
 results=[analyze(p) for p in paths]
 sys.exit(1 if any(r['failures'] for r in results) else 0)
