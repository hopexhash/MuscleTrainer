#!/usr/bin/env python3
"""App icon generator: line-art torso with glowing cyan chest on the dark ground."""
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance
import math

S = 4096
BG=(5,9,11); BODY=(20,30,38); LIMB=(15,24,31); IDLE=(31,44,54); ACC=(43,212,238); LINE=(70,92,106)

img = Image.new('RGB',(S,S),BG)
draw = ImageDraw.Draw(img)
for y in range(S):
    t=y/S; c=(int(10-5*t),int(16-8*t),int(20-10*t))
    draw.line([(0,y),(S,y)],fill=c)

top,bot = 6,218
scale = S*0.80/(bot-top)
ox = S/2 - 100*scale
oy = S*0.10 - top*scale
def P(x,y): return (ox+x*scale, oy+y*scale)

def cubic(p0,p1,p2,p3,n=50):
    return [( (1-t)**3*p0[0]+3*(1-t)**2*t*p1[0]+3*(1-t)*t**2*p2[0]+t**3*p3[0],
              (1-t)**3*p0[1]+3*(1-t)**2*t*p1[1]+3*(1-t)*t**2*p2[1]+t**3*p3[1])
            for t in [i/n for i in range(n+1)]]
def ell_poly(cx,cy,rx,ry,deg=0,n=80):
    a=math.radians(deg); pts=[]
    for i in range(n):
        t=2*math.pi*i/n; x=rx*math.cos(t); y=ry*math.sin(t)
        pts.append(P(cx + x*math.cos(a)-y*math.sin(a), cy + x*math.sin(a)+y*math.cos(a)))
    return pts
def rrect_poly(x,y,w,h,r,deg=0,pivot=None,n=12):
    cs=[(x+w-r,y+r,-90,0),(x+w-r,y+h-r,0,90),(x+r,y+h-r,90,180),(x+r,y+r,180,270)]
    pts=[]
    for cx,cy,a0,a1 in cs:
        for i in range(n+1):
            a=math.radians(a0+(a1-a0)*i/n)
            pts.append((cx+r*math.cos(a), cy+r*math.sin(a)))
    if deg:
        px,py=pivot or (x+w/2,y+h/2); a=math.radians(deg); out=[]
        for X,Y in pts:
            dx,dy=X-px,Y-py
            out.append((px+dx*math.cos(a)-dy*math.sin(a), py+dx*math.sin(a)+dy*math.cos(a)))
        pts=out
    return [P(X,Y) for X,Y in pts]
def mirror(pts): return [ (2*(ox+100*scale)-x, y) for x,y in pts ]

seam = max(3, int(S/340))
def muscle(pts, fill): draw.polygon(pts, fill=fill, outline=BG, width=seam)

torso = cubic((62,76),(57,92),(61,122),(67,150)) + [(73,192)] \
      + cubic((73,192),(75,206),(83,213),(100,213))[1:] \
      + cubic((100,213),(117,213),(125,206),(127,192))[1:] + [(133,150)] \
      + cubic((133,150),(139,122),(143,92),(138,76))[1:] \
      + cubic((138,76),(130,67),(118,63),(100,63))[1:] \
      + cubic((100,63),(82,63),(70,67),(62,76))[1:]
torso_pts=[P(x,y) for x,y in torso]

aura=Image.new('L',(S,S),0); ad=ImageDraw.Draw(aura)
acx,acy=P(100,95); R=int(S*0.34)
for i in range(80,0,-1):
    r=R*i/80; a=int(60*(1-i/80)**1.7)
    ad.ellipse([acx-r,acy-r,acx+r,acy+r],fill=a)
aura=aura.filter(ImageFilter.GaussianBlur(S//70))
img=Image.composite(Image.new('RGB',(S,S),ACC),img,aura); draw=ImageDraw.Draw(img)

for pts in [rrect_poly(43,80,22,66,11,5,(54,113)), rrect_poly(36,142,19,64,9.5,6,(45,174)), ell_poly(42,216,8.5,12)]:
    draw.polygon(pts,fill=LIMB); draw.polygon(mirror(pts),fill=LIMB)
draw.polygon(torso_pts,fill=BODY)
draw.polygon(rrect_poly(90,44,20,16,7),fill=LIMB)
draw.polygon(ell_poly(100,30,17,21),fill=BODY)

glow=Image.new('L',(S,S),0); gd=ImageDraw.Draw(glow)
for cx in (88,112):
    gx,gy=P(cx,90); gr=17*scale
    gd.ellipse([gx-gr,gy-gr,gx+gr,gy+gr],fill=110)
glow=glow.filter(ImageFilter.GaussianBlur(S//55))
img=Image.composite(Image.new('RGB',(S,S),ACC),img,glow); draw=ImageDraw.Draw(img)

muscle(ell_poly(63,86,12.5,14,-8),IDLE); muscle(mirror(ell_poly(63,86,12.5,14,-8)),IDLE)
muscle(ell_poly(77,82,10,11.5),IDLE);   muscle(mirror(ell_poly(77,82,10,11.5)),IDLE)
muscle(ell_poly(57,118,9.5,19,6),IDLE); muscle(mirror(ell_poly(57,118,9.5,19,6)),IDLE)
muscle(ell_poly(47,170,8.5,24,6),IDLE); muscle(mirror(ell_poly(47,170,8.5,24,6)),IDLE)
muscle(ell_poly(81,138,6.5,21,-5),IDLE);muscle(mirror(ell_poly(81,138,6.5,21,-5)),IDLE)
for yy,h in [(113,11),(127,11),(141,11),(155,10)]:
    muscle(rrect_poly(89,yy,9.5,h,3),IDLE); muscle(mirror(rrect_poly(89,yy,9.5,h,3)),IDLE)
chest=rrect_poly(78,76,20.5,31,9,-4,(88,91))
muscle(chest,ACC); muscle(mirror(chest),ACC)

img=img.resize((1024,1024),Image.LANCZOS)
img=ImageEnhance.Brightness(img).enhance(1.18)
img.save('MuscleTrainer/Assets.xcassets/AppIcon.appiconset/AppIcon.png')
print('icon regenerated (cyan)')
