from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import numpy as np
root=Path(__file__).resolve().parents[1]
# New original sole masks: contour, heel, arch and broken tread, not a filled quad.
w,h=128,256
mask=Image.new('L',(w,h));draw=ImageDraw.Draw(mask)
poly=[(47,13),(68,10),(85,21),(96,43),(100,77),(96,111),(88,137),(83,161),(88,183),(86,220),(75,239),(48,241),(31,230),(27,208),(31,176),(39,151),(37,128),(28,100),(26,67),(30,36)]
draw.polygon(poly,fill=235);mask=mask.filter(ImageFilter.GaussianBlur(2.0))
a=np.asarray(mask,dtype=np.float32)/255
yy,xx=np.indices((h,w));rng=np.random.default_rng(410)
rough=rng.uniform(.80,1,(h,w));edge=np.asarray(mask.filter(ImageFilter.GaussianBlur(3)),dtype=np.float32)/255
tread=np.zeros((h,w),np.float32)
for y in [48,67,86,105,124,187,205,222]:tread[(abs(yy-y)<2)&(abs(xx-62)<27)]=.25
depth=np.maximum(0,a-tread)*.55
dy,dx=np.gradient(depth);normal=np.stack([.5-dx*2.6,.5+dy*2.6,np.ones_like(a)],axis=2)
normal=(normal*255).clip(0,255).astype('uint8');Image.fromarray(normal).save(root/'assets/memorial/footprints/sole_normal.png')
for name,color in [('snow',(86,94,99)),('mud',(51,42,30))]:
    data=np.zeros((h,w,4),np.uint8)
    for c,value in enumerate(color):data[:,:,c]=(value+edge*25+tread*65).clip(0,255).astype('uint8')
    data[:,:,3]=(a*rough*230).astype('uint8');Image.fromarray(data).save(root/f'assets/memorial/footprints/sole_{name}.png')

r=root/"assets/memorial/footprints"
for name in ["snow","mud"]:
    Image.open(r/f"sole_{name}.png").transpose(Image.Transpose.FLIP_LEFT_RIGHT).save(r/f"sole_{name}_right.png")
a=np.array(Image.open(r/"sole_normal.png").transpose(Image.Transpose.FLIP_LEFT_RIGHT));a[:,:,0]=255-a[:,:,0];Image.fromarray(a).save(r/"sole_normal_right.png")
