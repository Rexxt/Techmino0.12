local gc=love.graphics
local mt=love.math
local Timer=love.timer.getTime
local int,ceil,rnd=math.floor,math.ceil,math.random
local max,min,abs,sin=math.max,math.min,math.abs,math.sin
local ins,rem=table.insert,table.remove
local format=string.format
local SCR=SCR
local setFont=setFont

--------------------------<Data>--------------------------
local gameEnv0={
	das=10,arr=2,sddas=2,sdarr=2,
	ihs=true,irs=true,ims=true,
	swap=true,

	ghost=.3,center=1,
	smooth=false,grid=false,
	bagLine=false,
	text=true,
	score=true,
	lockFX=2,
	dropFX=2,
	moveFX=2,
	clearFX=2,
	shakeFX=3,

	highCam=false,
	nextPos=false,

	drop=60,lock=60,
	wait=0,fall=0,
	bone=false,
	next=6,
	hold=true,oncehold=true,
	ospin=true,
	sequence="bag",
	freshMethod=NULL,
	bag={1,2,3,4,5,6,7},
	face=NULL,skin=NULL,
	mission=NULL,

	life=0,
	pushSpeed=3,
	block=true,
	noTele=false,
	visible="show",
	freshLimit=1e99,easyFresh=true,

	Fkey=NULL,
	keyCancel={},
	fine=false,fineKill=false,
	missionKill=false,
	target=1e99,dropPiece=NULL,
	mindas=0,minarr=0,minsdarr=0,

	bg="none",bgm="race"
}
local scs=spinCenters
local kickList=require("parts/kickList")
local CCblockID={6,5,4,3,2,1,0}
--------------------------</Data>--------------------------

--------------------------<LIB>--------------------------
local player={}--Player object
local PLY={}--Lib
--------------------------</LIB>--------------------------

--------------------------<Update>--------------------------
local function updateLine(P)--Attacks, line pushing, cam moving
	local bf=P.atkBuffer
	for i=#bf,1,-1 do
		local A=bf[i]
		A.time=A.time+1
		if not A.sent then
			if A.countdown>0 then
				A.countdown=max(A.countdown-GAME.garbageSpeed,0)
			end
		else
			if A.time>20 then
				rem(bf,i)
			end
		end
	end

	local y=P.fieldBeneath
	if y>0 then
		P.fieldBeneath=max(y-P.gameEnv.pushSpeed,0)
	end

	if P.gameEnv.highCam then
		local f=P.fieldUp
		if not P.alive then
			y=0
		else
			y=30*max(min(#P.field-19.5-P.fieldBeneath/30,P.imgY-17),0)
		end
		if f~=y then
			P.fieldUp=f>y and max(f*.95+y*.05-2,y)or min(f*.97+y*.03+1,y)
		end
	end
end
local function updateFXs(P,dt)
	if P.stat.score>P.score1 then
		if P.stat.score-P.score1<10 then
			P.score1=P.score1+1
		else
			P.score1=int(min(P.score1*.9+P.stat.score*.1+1))
		end
	end

	--LockFX
	for i=#P.lockFX,1,-1 do
		local S=P.lockFX[i]
		S[3]=S[3]+S[4]*dt
		if S[3]>1 then
			rem(P.lockFX,i)
		end
	end

	--DropFX
	for i=#P.dropFX,1,-1 do
		local S=P.dropFX[i]
		S[5]=S[5]+S[6]*dt
		if S[5]>1 then
			rem(P.dropFX,i)
		end
	end

	--MoveFX
	for i=#P.moveFX,1,-1 do
		local S=P.moveFX[i]
		S[4]=S[4]+S[5]*dt
		if S[4]>1 then
			rem(P.moveFX,i)
		end
	end

	--ClearFX
	for i=#P.clearFX,1,-1 do
		local S=P.clearFX[i]
		S[2]=S[2]+S[3]*dt
		if S[2]>1 then
			rem(P.clearFX,i)
		end
	end

	--Field shaking
	if P.gameEnv.shakeFX then
		local O=P.fieldOff
		O.vx,O.vy=O.vx*.8-abs(O.x)^1.2*(O.x>0 and .1 or -.1),O.vy*.8-abs(O.y)^1.2*(O.y>0 and .1 or -.1)
		O.x,O.y=O.x+O.vx,O.y+O.vy
		if abs(O.x)<.3 then O.x=0 end
		if abs(O.y)<.3 then O.y=0 end
	end

	if P.bonus then
		TEXT.update(P.bonus)
	end
end
local function updateTasks(P)
	local L=P.tasks
	for i=#L,1,-1 do
		if L[i].code(P,L[i].data)then rem(L,i)end
	end
end
local function Pupdate_alive(P,dt)
	if P.timing then P.stat.time=P.stat.time+dt end
	if P.keyRec then--Update speeds
		local _=GAME.frame

		local v=0
		for i=2,10 do v=v+i*(i-1)*7.2/(_-P.keyTime[i]+1)end
		P.keySpeed=P.keySpeed*.99+v*.1

		v=0
		for i=2,10 do v=v+i*(i-1)*7.2/(_-P.dropTime[i])end
		P.dropSpeed=P.dropSpeed*.99+v*.1

		if modeEnv.royaleMode then
			if P.keyPressing[9]then
				P.swappingAtkMode=min(P.swappingAtkMode+2,30)
			else
				P.swappingAtkMode=P.swappingAtkMode+((#P.field>15 and P.swappingAtkMode>4 or P.swappingAtkMode>8)and -1 or 1)
			end
		end
	end

	if not P.human and P.control and P.waiting==-1 then
		local C=P.AI_keys
		P.AI_delay=P.AI_delay-1
		if not C[1]then
			P.AI_stage=AIFUNC[P.AI_mode][P.AI_stage](P,C)
		elseif P.AI_delay<=0 then
			P:pressKey(C[1])P:releaseKey(C[1])
			if P.AI_mode~="CC"or C[1]>3 then
				P.AI_delay=P.AI_delay0*2
			else
				P.AI_delay=P.AI_delay0*.5
			end
			rem(C,1)
		end
	end

	--Fresh visible time
	if not P.keepVisible then
		for j=1,#P.field do for i=1,10 do
			if P.visTime[j][i]>0 then P.visTime[j][i]=P.visTime[j][i]-1 end
		end end
	end

	--Moving pressed
	if P.movDir~=0 then
		local das,arr=P.gameEnv.das,P.gameEnv.arr
		local mov=P.moving
		if P.waiting==-1 then
			if P.movDir==1 then
				if P.keyPressing[2]then
					if arr>0 then
						if mov==das+arr or mov==das then
							if not P.cur or P:ifoverlap(P.cur.bk,P.curX+1,P.curY)then
								mov=das+arr-1
							else
								P.act.moveRight(P,true)
								mov=das
							end
						end
						mov=mov+1
					else
						if mov==das then
							P.act.insRight(P,true)
						else
							mov=mov+1
						end
					end
					if mov>=das and P.gameEnv.shakeFX and P.cur and P:ifoverlap(P.cur.bk,P.curX+1,P.curY)then
						P.fieldOff.vx=P.gameEnv.shakeFX*.5
					end
				else
					P.movDir=0
				end
			else
				if P.keyPressing[1]then
					if arr>0 then
						if mov==das+arr or mov==das then
							if not P.cur or P:ifoverlap(P.cur.bk,P.curX-1,P.curY)then
								mov=das+arr-1
							else
								P.act.moveLeft(P,true)
								mov=das
							end
						end
						mov=mov+1
					else
						if mov==das then
							P.act.insLeft(P,true)
						else
							mov=mov+1
						end
					end
					if mov>=das and P.gameEnv.shakeFX and P.cur and P:ifoverlap(P.cur.bk,P.curX-1,P.curY)then
						P.fieldOff.vx=-P.gameEnv.shakeFX*.5
					end
				else
					P.movDir=0
				end
			end
		elseif mov<das then
			mov=mov+1
		end
		P.moving=mov
	end

	--Drop pressed
	if P.keyPressing[7]and not P.keyPressing[9]then
		local d=P.downing-P.gameEnv.sddas
		P.downing=P.downing+1
		if d>1 then
			if P.gameEnv.sdarr>0 then
				if d%P.gameEnv.sdarr==0 then
					P.act.down1(P)
				end
			else
				P.act.insDown(P)
			end
			if P.gameEnv.shakeFX then
				P.fieldOff.vy=P.gameEnv.shakeFX*.3
			end
		end
	else
		P.downing=0
	end

	--Falling animation
	if P.falling>=0 then
		P.falling=P.falling-1
		if P.falling>=0 then
			goto stop
		else
			local L=#P.clearingRow
			if P.sound and P.gameEnv.fall>0 and #P.field+L>P.clearingRow[L]then SFX.play("fall")end
			P.clearingRow={}
		end
	end

	--Try spawn new block
	if not P.control then goto stop end
	if P.waiting>=0 then
		P.waiting=P.waiting-1
		if P.waiting<0 then P:popNext()end
		goto stop
	end

	--Natural block falling
	if P.cur then
		if P.curY>P.imgY then
			local D=P.dropDelay
			if D>1 then
				P.dropDelay=D-1
				goto stop
			end

			if D==1 then
				if P.gameEnv.moveFX and P.gameEnv.block then
					P:createMoveFX("down")
				end
				P.curY=P.curY-1
			else
				D=1/D--Fall dist
				if D>P.curY-P.imgY then D=P.curY-P.imgY end
				if P.gameEnv.moveFX and P.gameEnv.block then
					for _=1,D do
						P:createMoveFX("down")
						P.curY=P.curY-1
					end
				else
					P.curY=P.curY-D
				end
			end
			P:freshBlock(true,true)
			P.spinLast=false

			if P.imgY~=P.curY then
				P.dropDelay=P.gameEnv.drop
			elseif P.AI_mode=="CC"then
				CC.updateField(P)
				if not P.AIdata._20G and P.gameEnv.drop<P.AI_delay0*.5 then
					CC.switch20G(P)
				end
			end
		else
			P.lockDelay=P.lockDelay-1
			if P.lockDelay>=0 then goto stop end
			P:drop()
			if P.AI_mode=="CC"then
				CC.updateField(P)
			end
		end
	end
	::stop::
	if P.b2b1==P.b2b then
	elseif P.b2b1<P.b2b then
		P.b2b1=min(P.b2b1*.98+P.b2b*.02+.4,P.b2b)
	else
		P.b2b1=max(P.b2b1*.95+P.b2b*.05-.6,P.b2b)
	end
	if P.finesseComboTime>0 then
		P.finesseComboTime=P.finesseComboTime-1
	end
	updateLine(P)
	updateFXs(P,dt)
	updateTasks(P)
end
local function Pupdate_dead(P,dt)
	if P.timing then P.stat.time=P.stat.time+dt end
	if P.keyRec then
		P.keySpeed=P.keySpeed*.96+P.stat.key/P.stat.time*60*.04
		P.dropSpeed=P.dropSpeed*.96+P.stat.piece/P.stat.time*60*.04
		--Final average speeds
		if modeEnv.royaleMode then
			P.swappingAtkMode=min(P.swappingAtkMode+2,30)
		end
	end
	if P.falling>=0 then
		P.falling=P.falling-1
		if P.falling<0 then
			local L=#P.clearingRow
			if P.sound and P.gameEnv.fall>0 and #P.field+L>P.clearingRow[L]then SFX.play("fall")end
			P.clearingRow={}
		end
	end
	if P.b2b1>0 then
		P.b2b1=max(0,P.b2b1*.92-1)
	end
	if P.finesseComboTime>0 then
		P.finesseComboTime=P.finesseComboTime-1
	end
	updateLine(P)
	updateFXs(P,dt)
	updateTasks(P)
end
--------------------------</Update>--------------------------

--------------------------<Paint>--------------------------
local frameColor={
	[0]=COLOR.white,
	COLOR.lGreen,
	COLOR.lBlue,
	COLOR.lPurple,
	COLOR.lOrange,
}
--local function drawCell(y,x,id)gc.draw(SKIN.curText[id],30*x-30,-30*y)end
local function drawGrid(P)
	local FBN,FUP=P.fieldBeneath,P.fieldUp
	gc.setLineWidth(1)
	gc.setColor(1,1,1,.2)
	for x=1,9 do
		gc.line(30*x,-10,30*x,600)
	end
	for y=0,19 do
		y=30*(y-int((FBN+FUP)/30))+FBN+FUP
		gc.line(0,y,300,y)
	end
end
local function drawField(P)
	local V,F=P.visTime,P.field
	local start=int((P.fieldBeneath+P.fieldUp)/30+1)
	local rep=GAME.replaying
	local texture=SKIN.curText
	if P.falling==-1 then--Blocks only
		for j=start,min(start+21,#F)do
			for i=1,10 do
				if F[j][i]>0 then
					if V[j][i]>0 then
						gc.setColor(1,1,1,min(V[j][i]*.05,1))
						gc.draw(texture[F[j][i]],30*i-30,-30*j)-- drawCell(j,i,F[j][i])
					elseif rep then
						gc.setColor(1,1,1,.3+.08*sin(.5*(j-i)+Timer()*4))
						gc.rectangle("fill",30*i-30,-30*j,30,30)
					end
				end
			end
		end
	else--With falling animation
		local ENV=P.gameEnv
		local stepY=ENV.smooth and(P.falling/(ENV.fall+1))^2.5*30 or 30
		local A=P.falling/ENV.fall
		local h=1
		gc.push("transform")
			for j=start,min(start+21,#F)do
				while j==P.clearingRow[h]do
					h=h+1
					gc.translate(0,-stepY)
					gc.setColor(1,1,1,A)
					gc.rectangle("fill",0,30-30*j,300,stepY)
				end
				for i=1,10 do
					if F[j][i]>0 then
						if V[j][i]>0 then
							gc.setColor(1,1,1,min(V[j][i]*.05,1))
							gc.draw(texture[F[j][i]],30*i-30,-30*j)-- drawCell(j,i,F[j][i])
						elseif rep then
							gc.setColor(1,1,1,.2)
							gc.rectangle("fill",30*i-30,-30*j,30,30)
						end
					end
				end
			end
		gc.pop()
	end
end
local function drawFXs(P)
	--LockFX
	for i=1,#P.lockFX do
		local S=P.lockFX[i]
		if S[3]<.5 then
			gc.setColor(1,1,1,2*S[3])
			gc.rectangle("fill",S[1],S[2],60*S[3],30)
		else
			gc.setColor(1,1,1,2-2*S[3])
			gc.rectangle("fill",S[1]+30,S[2],60*S[3]-60,30)
		end
	end

	--DropFX
	for i=1,#P.dropFX do
		local S=P.dropFX[i]
		gc.setColor(1,1,1,.6-S[5]*.6)
		local w=30*S[3]*(1-S[5]*.5)
		gc.rectangle("fill",30*S[1]-30+15*S[3]-w*.5,-30*S[2],w,30*S[4])
	end

	--MoveFX
	local texture=SKIN.curText
	for i=1,#P.moveFX do
		local S=P.moveFX[i]
		gc.setColor(1,1,1,.6-S[4]*.6)
		gc.draw(texture[S[1]],30*S[2]-30,-30*S[3])-- drawCell(S[3],S[2],S[1])
	end

	--ClearFX
	for i=1,#P.clearFX do
		local S=P.clearFX[i]
		local t=S[2]
		local x=t<.3 and 1-(3.3333*t-1)^2 or 1
		local y=t<.2 and 5*t or 1-1.25*(t-.2)
		gc.setColor(1,1,1,y)
		gc.rectangle("fill",150-x*150,15-S[1]*30-y*15,300*x,y*30)
	end
end
local function drawGhost(P,clr)
	gc.setColor(1,1,1,P.gameEnv.ghost)
	local texture=SKIN.curText
	for i=1,P.r do for j=1,P.c do
		if P.cur.bk[i][j]then
			gc.draw(texture[clr],30*(j+P.curX-1)-30,-30*(i+P.imgY-1))-- drawCell(i+P.imgY-1,j+P.curX-1,clr)
		end
	end end
end
local function drawBlockOutline(P,texture,trans)
	SHADER.alpha:send("a",trans)
	gc.setShader(SHADER.alpha)
	for i=1,P.r do for j=1,P.c do
		if P.cur.bk[i][j]then
			local x=30*(j+P.curX)-60-3
			local y=30-30*(i+P.curY)-3
			gc.draw(texture,x,y)
			gc.draw(texture,x+6,y+6)
			gc.draw(texture,x+6,y)
			gc.draw(texture,x,y+6)
		end
	end end
	gc.setShader()
end
local function drawBlock(P,clr)
	gc.setColor(1,1,1)
	local texture=SKIN.curText
	for i=1,P.r do for j=1,P.c do
		if P.cur.bk[i][j]then
			gc.draw(texture[clr],30*(j+P.curX-1)-30,-30*(i+P.curY-1))-- drawCell(i+P.curY-1,j+P.curX-1,clr)
		end
	end end
end
local function drawNextPreview(P,B)
	gc.setColor(1,1,1,.8)
	local x=int(6-#B[1]*.5)
	local y=21+ceil(P.fieldBeneath/30)
	for i=1,#B do for j=1,#B[1]do
		if B[i][j]then
			gc.draw(puzzleMark[-1],30*(x+j-2),30*(1-y-i))
		end
	end end
end
local function drawHold(P,clr)
	local B=P.hd.bk
	local texture=SKIN.curText
	for i=1,#B do for j=1,#B[1]do
		if B[i][j]then
			gc.draw(texture[clr],30*(j+2.06-#B[1]*.5)-30,-30*(i+1.36-#B*.5))-- drawCell(i+1.36-#B*.5,j+2.06-#B[1]*.5,clr)
		end
	end end
end

local Pdraw_norm do
	local attackColor={
		{COLOR.dGrey,COLOR.white},
		{COLOR.grey,COLOR.white},
		{COLOR.lPurple,COLOR.white},
		{COLOR.lRed,COLOR.white},
		{COLOR.dGreen,COLOR.cyan},
	}
	local RCPB={10,33,200,33,105,5,105,60}
	local function drawDial(x,y,speed)
		gc.setColor(1,1,1)
		mStr(int(speed),x,y-18)

		gc.setLineWidth(4)
		gc.setColor(1,1,1,.4)
		gc.circle("line",x,y,30,10)

		gc.setLineWidth(2)
		gc.setColor(1,1,1,.6)
		gc.circle("line",x,y,30,10)

		gc.setColor(1,1,1,.8)
		gc.draw(IMG.dialNeedle,x,y,2.094+(speed<=175 and .02094*speed or 4.712-52.36/(speed-125)),nil,nil,5,4)
	end
	function Pdraw_norm(P)
		local _
		local ENV=P.gameEnv
		local FBN,FUP=P.fieldBeneath,P.fieldUp
		gc.push("transform")
			gc.translate(P.x,P.y)gc.scale(P.size)

			--Field-related things
			gc.push("transform")
				gc.translate(150,70)

				--Things shake with field
				gc.push("transform")
					gc.translate(P.fieldOff.x,P.fieldOff.y)

					--Fill field
					gc.setColor(0,0,0,.6)
					gc.rectangle("fill",0,-10,300,610)

					--Draw grid
					if ENV.grid then drawGrid(P)end

					--In-field things
					gc.push("transform")
						gc.translate(0,600+FBN+FUP)
						gc.setScissor(SCR.x+(P.absFieldX+P.fieldOff.x)*SCR.k,SCR.y+(P.absFieldY+P.fieldOff.y)*SCR.k,300*P.size*SCR.k,610*P.size*SCR.k)

						--Draw dangerous area
						gc.setColor(1,0,0,.3)
						gc.rectangle("fill",0,-600,300,-610-FUP-FBN)

						--Draw field
						drawField(P)

						--Draw spawn line
						gc.setColor(1,sin(Timer())*.4+.5,0,.5)
						gc.setLineWidth(4)
						gc.line(0,-600-FBN,300,-600-FBN)

						--Draw FXs
						drawFXs(P)

						--Draw current block
						if P.cur and P.waiting==-1 then
							local curColor=P.cur.color

							--Draw ghost
							if ENV.ghost then drawGhost(P,curColor)end

							local dy=ENV.smooth and P.imgY~=P.curY and(P.dropDelay/ENV.drop-1)*30 or 0
							gc.translate(0,-dy)
							local trans=P.lockDelay/ENV.lock

							--Draw block
							if ENV.block then
								drawBlockOutline(P,SKIN.curText[curColor],trans)
								drawBlock(P,curColor)
							end

							--Draw rotate center
							local x=30*(P.curX+P.sc[2])-15
							if ENV.center and ENV.block then
								gc.setColor(1,1,1,ENV.center)
								gc.draw(IMG.spinCenter,x,-30*(P.curY+P.sc[1])+15,nil,nil,nil,4,4)
							end
							gc.translate(0,dy)
							if ENV.center and ENV.ghost then
								gc.setColor(1,1,1,trans*ENV.center)
								gc.draw(IMG.spinCenter,x,-30*(P.imgY+P.sc[1])+15,nil,nil,nil,4,4)
							end
						end

						--Draw next preview
						if ENV.nextPos and P.next[1]then
							drawNextPreview(P,P.next[1].bk)
						end

						gc.setScissor()
					gc.pop()

					gc.setLineWidth(2)
					gc.setColor(P.frameColor)
					gc.rectangle("line",-1,-11,302,612)--Boarder
					gc.rectangle("line",301,-3,15,604)--AtkBuffer boarder
					gc.rectangle("line",-16,-3,15,604)--B2b bar boarder

					--Buffer line
					local h=0
					for i=1,#P.atkBuffer do
						local A=P.atkBuffer[i]
						local bar=A.amount*30
						if h+bar>600 then bar=600-h end
						if not A.sent then
							--Appear
							if A.time<20 then
								bar=bar*(20*A.time)^.5*.05
							end
							if A.countdown>0 then
								--Timing
								gc.setColor(attackColor[A.lv][1])
								gc.rectangle("fill",303,599-h,11,-bar)
								gc.setColor(attackColor[A.lv][2])
								gc.rectangle("fill",303,599-h-bar,11,bar*(1-A.countdown/A.cd0))
							else
								--Warning
								local t=math.sin((Timer()-i)*30)*.5+.5
								local c1,c2=attackColor[A.lv][1],attackColor[A.lv][2]
								gc.setColor(c1[1]*t+c2[1]*(1-t),c1[2]*t+c2[2]*(1-t),c1[3]*t+c2[3]*(1-t))
								gc.rectangle("fill",303,599-h,11,-bar)
							end
						else
							gc.setColor(attackColor[A.lv][1])
							bar=bar*(20-A.time)*.05
							gc.rectangle("fill",303,599-h,11,-bar)
							--Disappear
						end
						h=h+bar
					end

					--B2B indictator
					local a,b=P.b2b,P.b2b1 if a>b then a,b=b,a end
					gc.setColor(.8,1,.2)
					gc.rectangle("fill",-14,599,11,-b*.5)
					gc.setColor(P.b2b<40 and COLOR.white or P.b2b<=1e3 and COLOR.lRed or COLOR.lBlue)
					gc.rectangle("fill",-14,599,11,-a*.5)
					gc.setColor(1,1,1)
					if Timer()%.5<.3 then
						gc.rectangle("fill",-15,b<40 and 578.5 or 98.5,13,3)
					end

					--LockDelay indicator
					if ENV.easyFresh then
						gc.setColor(1,1,1)
					else
						gc.setColor(1,.26,.26)
					end
					if P.lockDelay>=0 then
						gc.rectangle("fill",0,602,300*P.lockDelay/ENV.lock,6)--Lock delay indicator
					end
					local x=3
					for _=1,min(ENV.freshLimit-P.freshTime,15)do
						gc.rectangle("fill",x,615,14,5)
						x=x+20
					end

					--Draw Hold
					if ENV.hold then
						gc.push("transform")
						gc.translate(-140,116)
							gc.setColor(0,0,0,.4)gc.rectangle("fill",0,-80,124,80)
							gc.setColor(1,1,1)gc.rectangle("line",0,-80,124,80)
							if P.holded then gc.setColor(.6,.4,.4)end
							mText(drawableText.hold,62,-131)
							if P.hd then drawHold(P,P.hd.color)end
						gc.pop()
					end

					--Draw Next(s)
					local N=ENV.next*72
					if ENV.next>0 then
						gc.setColor(0,0,0,.4)gc.rectangle("fill",316,36,124,N)
						gc.setColor(1,1,1)gc.rectangle("line",316,36,124,N)
						mText(drawableText.next,378,-15)
						N=1
						local texture=SKIN.curText
						while N<=ENV.next and P.next[N]do
							local bk,clr=P.next[N].bk,P.next[N].color
							for i=1,#bk do for j=1,#bk[1] do
								if bk[i][j]then
									gc.draw(texture[clr],30*(j+12.6-#bk[1]*.5)-30,-30*(i-2.4*N-#bk*.5))-- drawCell(i-2.4*N-#bk*.5,j+12.6-#bk[1]*.5,clr)
								end
							end end
							N=N+1
						end
					end

					--Draw Bagline(s)
					if ENV.bagLine then
						local L=ENV.bagLen
						local C=-P.pieceCount%L--Phase
						gc.setColor(.8,.5,.5)
						for i=C,N-1,L do
							local y=72*i+36
							gc.line(318+P.fieldOff.x,y,438,y)
						end
					end

					--Draw target selecting pad
					if modeEnv.royaleMode then
						if P.atkMode then
							gc.setColor(1,.8,0,P.swappingAtkMode*.02)
							gc.rectangle("fill",RCPB[2*P.atkMode-1],RCPB[2*P.atkMode],90,35,8,4)
						end
						gc.setColor(1,1,1,P.swappingAtkMode*.025)
						setFont(18)
						for i=1,4 do
							gc.rectangle("line",RCPB[2*i-1],RCPB[2*i],90,35,8,4)
							mStr(text.atkModeName[i],RCPB[2*i-1]+45,RCPB[2*i]+3)
						end
					end
				gc.pop()

				--Bonus texts
				TEXT.draw(P.bonus)

				--Display Ys
				-- gc.setLineWidth(6)
				-- if P.curY then	gc.setColor(1,.4,0,.42)gc.line(0,611-P.curY*30,300,611-P.curY*30)end
				-- if P.imgY then	gc.setColor(0,1,.4,.42)gc.line(0,615-P.imgY*30,300,615-P.imgY*30)end
				-- if P.minY then	gc.setColor(0,.4,1,.42)gc.line(0,619-P.minY*30,300,619-P.minY*30)end
				-- 				gc.setColor(0,.4,1,.42)gc.line(0,600-P.garbageBeneath*30,300,600-P.garbageBeneath*30)
			gc.pop()

			--Speed dials
			setFont(25)
			drawDial(510,580,P.dropSpeed)
			drawDial(555,635,P.keySpeed)
			gc.setColor(1,1,1)
			gc.draw(drawableText.bpm,540,550)
			gc.draw(drawableText.kpm,494,643)

			--Score & Time
			setFont(25)
			gc.setColor(0,0,0,.3)
			gc.print(P.score1,18,579)
			gc.print(format("%.2f",P.stat.time),18,609)

			gc.setColor(COLOR.lYellow)gc.print(P.score1,20,580)
			gc.setColor(COLOR.sky)gc.print(format("%.2f",P.stat.time),20,610)

			--FinesseCombo
			if P.finesseCombo>2 then
				_=P.finesseComboTime
				local T=P.finesseCombo.."x"
				if _>0 then
					gc.setColor(1,1,1,_*.2)
					gc.print(T,20,640)
					gc.setColor(1,1,1,1.2-_*.1)
					gc.push("transform")
					gc.translate(20,670)
					gc.scale(1+_*.08)
					gc.print(T,0,-30)
					gc.pop()
				else
					gc.setColor(1,1,1)
					gc.print(T,20,640)
				end
			end

			--Lives
			if P.life>0 then
				gc.setColor(1,1,1)
				if P.life<=3 then
					for i=1,P.life do
						gc.draw(IMG.lifeIcon,450+25*i,665,nil,.8)
					end
				else
					gc.draw(IMG.lifeIcon,475,665,nil,.8)
					setFont(20)
					gc.print("x",503,665)
					gc.print(P.life,517,665)
				end
			end

			--Other messages
			gc.setColor(1,1,1)
			if CURMODE.mesDisp then
				CURMODE.mesDisp(P)
			end

			--Missions
			if P.curMission then
				local missionEnum=missionEnum
				local L=ENV.mission

				--Draw current mission
				setFont(35)
				if ENV.missionKill then
					gc.setColor(1,.7+.2*sin(Timer()*6.26),.4)
				else
					gc.setColor(1,1,1)
				end
				gc.print(missionEnum[L[P.curMission]],85,180)

				--Draw next mission
				setFont(17)
				for i=1,3 do
					local t=L[P.curMission+i]
					if t then
						t=missionEnum[t]
						gc.print(t,87-26*i,187)
					else
						break
					end
				end
			end

			--Draw starting counter
			gc.setColor(1,1,1)
			if GAME.frame<180 then
				local count=179-GAME.frame
				gc.push("transform")
					gc.translate(305,290)
					setFont(95)
					if count%60>45 then gc.scale(1+(count%60-45)^2*.01,1)end
					mStr(int(count/60+1),0,0)
				gc.pop()
			end
		gc.pop()
	end
end
local function Pdraw_small(P)
	--Draw content
	P.frameWait=P.frameWait-1
	if P.frameWait==0 then
		P.frameWait=10
		gc.setCanvas(P.canvas)
		gc.clear(0,0,0,.4)
		gc.push("transform")
		gc.origin()
		gc.setColor(1,1,1,P.result and max(20-P.endCounter,0)*.05 or 1)

		--Field
		local F=P.field
		local texture=SKIN.curTextMini
		for j=1,#F do
			for i=1,10 do if F[j][i]>0 then
				gc.draw(texture[F[j][i]],6*i-6,120-6*j)
			end end
		end

		--Draw boarder
		if P.alive then
			gc.setLineWidth(2)
			gc.setColor(P.frameColor)
			gc.rectangle("line",0,0,60,120)
		end

		--Draw badge
		if modeEnv.royaleMode then
			gc.setColor(1,1,1)
			for i=1,P.strength do
				gc.draw(IMG.badgeIcon,12*i-7,4,nil,.5)
			end
		end

		--Draw result
		if P.result then
			gc.setColor(1,1,1,min(P.endCounter,60)*.01)
			setFont(17)mStr(P.result,32,47)
			setFont(15)mStr(P.modeData.event,30,82)
		end
		gc.pop()
		gc.setCanvas()
	end

	--Draw Canvas
	gc.setColor(1,1,1)
	gc.draw(P.canvas,P.x,P.y,nil,P.size*10)
	if P.killMark then
		gc.setLineWidth(3)
		gc.setColor(1,0,0,min(P.endCounter,25)*.04)
		gc.circle("line",P.centerX,P.centerY,(840-20*min(P.endCounter,30))*P.size)
	end
	setFont(30)
end
local function Pdraw_demo(P)
	local _
	local ENV=P.gameEnv
	local curColor=P.cur.color

	--Camera
	gc.push("transform")
		gc.translate(P.x,P.y)gc.scale(P.size)
		gc.push("transform")
			gc.translate(P.fieldOff.x,P.fieldOff.y)

			--Frame
			gc.setColor(0,0,0,.6)
			gc.rectangle("fill",0,0,300,600)
			gc.setLineWidth(2)
			gc.setColor(1,1,1)
			gc.rectangle("line",-1,-1,302,602)

			gc.push("transform")
				gc.translate(0,600)
				drawField(P)
				drawFXs(P)
				if P.cur and P.waiting==-1 then
					if ENV.ghost then drawGhost(P,curColor)end
					if ENV.block then
						drawBlockOutline(P,SKIN.curText[curColor],P.lockDelay/ENV.lock)
						drawBlock(P,curColor)
					end
				end
			gc.pop()

			--Draw hold
			local blockImg=TEXTURE.miniBlock
			if P.hd then
				local id=P.hd.id
				_=P.color[id]
				gc.setColor(_[1],_[2],_[3],.3)
				_=blockImg[id]
				gc.draw(_,15,30,nil,16,nil,0,_:getHeight()*.5)
			end

			--Draw next
			local N=1
			while N<=ENV.next and P.next[N]do
				local id=P.next[N].id
				_=P.color[id]
				gc.setColor(_[1],_[2],_[3],.3)
				_=blockImg[id]
				gc.draw(_,285,40*N-10,nil,16,nil,_:getWidth(),_:getHeight()*.5)
				N=N+1
			end
		gc.pop()
		TEXT.draw(P.bonus)
	gc.pop()
end
function player.drawTargetLine(P,r)
	if r<21+(P.fieldBeneath+P.fieldUp)/30 and r>0 then
		gc.setLineWidth(4)
		gc.setColor(1,r>10 and 0 or rnd(),.5)
		local dx,dy=150+P.fieldOff.x,70+P.fieldOff.y+P.fieldBeneath+P.fieldUp
		gc.line(dx,600-30*r+dy,300+dx,600-30*r+dy)
	end
end
--------------------------</Paint>--------------------------

--------------------------<Lib Func>--------------------------
local function without(L,e)
	for i=1,#L do
		if L[i]==e then return end
	end
	return true
end
local function getNewStatTable()
	local T={
		time=0,score=0,
		key=0,rotate=0,hold=0,
		extraPiece=0,finesseRate=0,
		piece=0,row=0,dig=0,
		atk=0,digatk=0,
		send=0,recv=0,pend=0,off=0,
		clear={},clears={},spin={},spins={},
		pc=0,hpc=0,b2b=0,b3b=0,
		maxCombo=0,maxFinesseCombo=0,
	}
	for i=1,25 do
		T.clear[i]={0,0,0,0,0,0}
		T.spin[i]={0,0,0,0,0,0,0}
		T.clears[i]=0
		T.spins[i]=0
	end
	return T
end
local function pressKey(P,i)
	if P.keyAvailable[i]then
		P.keyPressing[i]=true
		P.act[i](P)
		if P.control then
			if P.keyRec then
				ins(P.keyTime,1,GAME.frame)
				P.keyTime[11]=nil
			end
		end
		P.stat.key=P.stat.key+1
	end
end
local function releaseKey(P,i)
	P.keyPressing[i]=false
end
local function pressKey_Rec(P,i)
	if P.keyAvailable[i]then
		if GAME.recording then
			ins(GAME.rec,GAME.frame+1)
			ins(GAME.rec,i)
		end
		P.keyPressing[i]=true
		P.act[i](P)
		if P.control then
			if P.keyRec then
				ins(P.keyTime,1,GAME.frame)
				P.keyTime[11]=nil
			end
		end
		P.stat.key=P.stat.key+1
	end
end
local function releaseKey_Rec(P,i)
	if GAME.recording then
		ins(GAME.rec,GAME.frame+1)
		ins(GAME.rec,-i)
	end
	P.keyPressing[i]=false
end
local function loadGameEnv(P)--Load gameEnv
	P.gameEnv={}--Current game setting environment
	local ENV=P.gameEnv
	--Load game settings
	for k,v in next,gameEnv0 do
		if modeEnv[k]~=nil then
			v=modeEnv[k]				--Mode setting
			-- DBP("mode-"..k..":"..tostring(v))
		elseif GAME.setting[k]~=nil then
			v=GAME.setting[k]			--Game setting
			-- DBP("game-"..k..":"..tostring(v))
		elseif SETTING[k]~=nil then
			v=SETTING[k]				--Global setting
			-- DBP("global-"..k..":"..tostring(v))
		-- else
			-- DBP("default-"..k..":"..tostring(v))
		end
		if type(v)~="table"then--Default setting
			ENV[k]=v
		else
			ENV[k]=copyTable(v)
		end
	end
end
local function applyGameEnv(P)--Finish gameEnv processing
	local ENV=P.gameEnv

	P._20G=ENV.drop==0
	P.dropDelay=ENV.drop
	P.lockDelay=ENV.lock

	P.color={}
	for _=1,7 do
		P.color[_]=SKIN.libColor[ENV.skin[_]]
	end

	P.keepVisible=ENV.visible=="show"
	P.showTime=
		ENV.visible=="show"and 1e99 or
		ENV.visible=="time"and 300 or
		ENV.visible=="fast"and 20 or
		ENV.visible=="none"and 0

	P.life=ENV.life

	P.keyAvailable={true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true,true}
	if ENV.noTele then
		for i=11,20 do
			if i~=14 then
				P.keyAvailable[i]=false
				virtualkey[i].ava=false
			end
		end
	end
	for _,v in next,ENV.keyCancel do
		P.keyAvailable[v]=false
		virtualkey[v].ava=false
	end
	if P._20G then
		P.keyAvailable[7]=false
		virtualkey[7].ava=false
	end

	if type(ENV.mission)=="table"then
		P.curMission=1
	end

	ENV.das=max(ENV.das,ENV.mindas)
	ENV.arr=max(ENV.arr,ENV.minarr)
	ENV.sdarr=max(ENV.sdarr,ENV.minsdarr)
	ENV.next=min(ENV.next,SETTING.maxNext)

	if ENV.sequence~="bag"and ENV.sequence~="loop"then
		ENV.bagLine=false
	else
		ENV.bagLen=#ENV.bag
	end

	if ENV.next==0 then ENV.nextPos=false end

	if ENV.lockFX==0 then	ENV.lockFX=nil	end
	if ENV.dropFX==0 then	ENV.dropFX=nil	end
	if ENV.moveFX==0 then	ENV.moveFX=nil	end
	if ENV.clearFX==0 then	ENV.clearFX=nil end
	if ENV.shakeFX==0 then	ENV.shakeFX=nil	end

	if ENV.ghost==0 then	ENV.ghost=nil	end
	if ENV.center==0 then	ENV.center=nil	end
end

local prepareSequence do
	local freshMethod
	local freshPrepare={
		rnd=function(P)
			local bag=P.gameEnv.bag
			P:getNext(bag[rnd(#bag)])
			freshMethod.rnd(P)
		end,
		fixed=function(P)
			local bag=P.gameEnv.bag
			local L=#bag
			for i=1,L do
				P.seqData[i]=bag[L+1-i]
			end
			while #P.next<6 do
				if P.seqData[1]then
					P:getNext(rem(P.seqData))
				else
					break
				end
			end
		end,
	}
	freshMethod={
		none=NULL,
		bag=function(P)
			local bag=P.seqData
			while #P.next<6 do
				if #bag==0 then--Copy a new bag
					local bag0=P.gameEnv.bag
					for i=1,#bag0 do bag[i]=bag0[i]end
				end
				P:getNext(rem(bag,P:RND(#bag)))
			end
		end,
		his4=function(P)
			while #P.next<6 do
				local bag=P.gameEnv.bag
				local L=#bag
				for n=1,4 do
					local j,i=0
					repeat
						i=bag[P:RND(L)]
						j=j+1
					until i~=P.seqData[1]and i~=P.seqData[2]and i~=P.seqData[3]and i~=P.seqData[4]or j==4
					P.seqData[n]=i
					P:getNext(i)
				end
			end
		end,
		rnd=function(P)
			while #P.next<6 do
				local bag=P.gameEnv.bag
				local L=#bag
				for i=1,4 do
					local count=0
					repeat
						i=bag[P:RND(L)]
						count=count+1
					until i~=P.next[#P.next].id or count>=L
					P:getNext(i)
				end
			end
		end,
		reverb=function(P)
			local seq=P.seqData
			while #P.next<6 do
				if #seq==0 then
					local bag0=P.gameEnv.bag
					for i=1,#bag0 do seq[i]=bag0[i]end
					local bag={}
					repeat
						local r=rem(seq,P:RND(#bag))
						local p=1
						repeat
							ins(bag,r)
							p=p-.15-P:RND()
						until p<0
					until #seq==0
					for i=1,#bag do
						seq[i]=bag[i]
					end
				end
				P:getNext(rem(seq))
			end
		end,
		loop=function(P)
			while #P.next<6 do
				if #P.seqData==0 then
					local bag=P.gameEnv.bag
					local L=#bag
					for i=1,L do
						P.seqData[i]=bag[L+1-i]
					end
				end
				P:getNext(rem(P.seqData))
			end
		end,
		fixed=function(P)
			while #P.next<6 do
				if P.seqData[1]then
					P:getNext(rem(P.seqData))
				else
					if not(P.cur or P.hd)then P:lose(true)end
					return
				end
			end
		end,
	}
	function prepareSequence(P)--Call freshPrepare and set newNext
		local ENV=P.gameEnv
		if type(ENV.sequence)=="string"then
			P.newNext=freshMethod[ENV.sequence]
			if freshPrepare[ENV.sequence]then
				freshPrepare[ENV.sequence](P)
			else
				P:newNext()
			end
		else
			if type(ENV.freshMethod)=="function"then
				if ENV.sequence then ENV.sequence(P)end
				P.newNext=ENV.freshMethod
			else
				LOG.print("Wrong sequence generator code","warn")
				ENV.sequence="bag"
				prepareSequence(P)
			end
		end
	end
end
local function loadAI(P,AIdata)--Load AI params
	local ENV=P.gameEnv
	P.AI_mode=AIdata.type
	P.AI_stage=1
	P.AI_keys={}
	P.AI_delay=AIdata.delay or min(int(ENV.drop*.8),AIdata.delta*rnd()*4)
	P.AI_delay0=AIdata.delta
	P.AIdata={
		type=AIdata.type,
		delay=AIdata.delay,
		delta=AIdata.delta,

		next=AIdata.next,
		hold=AIdata.hold,
		_20G=P._20G,
		bag=AIdata.bag,
		node=AIdata.node,
	}
	if not CC then
		P.AI_mode="9S"
		P.AI_delay0=int(P.AI_delay0*.26)
	end
	if P.AI_mode=="CC"then
		P.RS=kickList.AIRS
		local opt,wei=CC.getConf()
			CC.fastWeights(wei)
			CC.setHold(opt,P.AIdata.hold)
			CC.set20G(opt,P.AIdata._20G)
			CC.setBag(opt,P.AIdata.bag=="bag")
			CC.setNode(opt,P.AIdata.node)
		P.AI_bot=CC.new(opt,wei)
		CC.free(opt)CC.free(wei)
		for i=1,AIdata.next do
			CC.addNext(P.AI_bot,CCblockID[P.next[i].id])
		end
	end
end
local function newEmptyPlayer(id,x,y,size)
	local P={id=id}
	PLAYERS[id]=P
	PLAYERS.alive[id]=P

	--Inherit functions of player class
	for k,v in next,player do P[k]=v end
	if P.id==1 and GAME.recording then
		P.pressKey=pressKey_Rec
		P.releaseKey=releaseKey_Rec
	else
		P.pressKey=pressKey
		P.releaseKey=releaseKey
	end
	P.update=Pupdate_alive

	P.fieldOff={x=0,y=0,vx=0,vy=0}--For shake FX
	P.x,P.y,P.size=x,y,size or 1
	P.frameColor=frameColor[0]

	P.small=P.size<.1--If draw in small mode
	if P.small then
		P.centerX,P.centerY=P.x+300*P.size,P.y+600*P.size
		P.canvas=love.graphics.newCanvas(60,120)
		P.frameWait=rnd(30,120)
		P.draw=Pdraw_small
	else
		P.keyRec=true--If calculate keySpeed
		P.centerX,P.centerY=P.x+300*P.size,P.y+370*P.size
		P.absFieldX=P.x+150*P.size
		P.absFieldY=P.y+60*P.size
		P.draw=Pdraw_norm
		P.bonus={}--Text objects
	end
	P.randGen=mt.newRandomGenerator(GAME.seed)

	P.small=false
	P.alive=true
	P.control=false
	P.timing=false
	P.stat=getNewStatTable()

	P.modeData={point=0,event=0,counter=0}--Data use by mode
	P.keyTime={}P.keySpeed=0
	P.dropTime={}P.dropSpeed=0
	for i=1,10 do P.keyTime[i]=-1e5 end
	for i=1,10 do P.dropTime[i]=-1e5 end

	P.field,P.visTime={},{}
	P.atkBuffer={sum=0}

	--Royale-related
	P.badge,P.strength=0,0
	P.atkMode,P.swappingAtkMode=1,20
	P.atker,P.atking,P.lastRecv={}

	P.dropDelay,P.lockDelay=0,0
	P.color={}
	P.showTime=nil
	P.keepVisible=true

	--P.cur={bk=matrix[2], id=shapeID, color=colorID, name=nameID}
	--P.sc,P.dir={0,0},0--SpinCenterCoord, direction
	--P.r,P.c=0,0--row, col
	--P.hd={...},same as P.cur
	-- P.curX,P.curY,P.imgY,P.minY=0,0,0,0--x,y,ghostY
	P.holded=false
	P.next={}
	P.seqData={}

	P.freshTime=0
	P.spinLast=false
	P.lastPiece={
		id=0,name=0,--block id/name

		finePts=0,--finesse Points

		row=0,dig=0,--lines/garbage cleared
		score=0,--score gained
		atk=0,exblock=0,--lines attack/defend
		off=0,send=0,--lines offset/sent

		spin=false,mini=false,--if spin/mini
		pc=false,hpc=false,--if pc/hpc
		special=false,--if special clear (spin, >=4, pc)
	}
	P.spinSeq=0--For Ospin, each digit mean a spin
	P.ctrlCount=0--Key press time, for finesse check
	P.pieceCount=0--Count pieces from next, for drawing bagline

	P.human=false
	P.sound=false
	P.RS=kickList.TRS

	-- P.newNext=nil--Call prepareSequence()to get a function to get new next

	P.keyPressing={}for i=1,12 do P.keyPressing[i]=false end
	P.movDir,P.moving,P.downing=0,0,0--Last move key,DAS charging,downDAS charging
	P.waiting,P.falling=-1,-1
	P.clearingRow,P.clearedRow={},{}--Clearing animation height,cleared row mark
	P.combo,P.b2b=0,0
	P.finesseCombo=0
	P.garbageBeneath=0
	P.fieldBeneath=0
	P.fieldUp=0

	P.score1,P.b2b1=0,0
	P.finesseComboTime=0
	P.dropFX,P.moveFX,P.lockFX,P.clearFX={},{},{},{}
	P.tasks={}--Tasks
	P.bonus={}--Texts

	P.endCounter=0--Used after gameover
	P.result=nil--String:"WIN"/"K.O."

	return P
end
--------------------------</Lib Func>--------------------------

--------------------------<FX>--------------------------
function player:showText(text,dx,dy,font,style,spd,stop)
	if self.gameEnv.text then
		ins(self.bonus,TEXT.getText(text,150+dx,300+dy,font*self.size,style,spd,stop))
	end
end
function player:showTextF(text,dx,dy,font,style,spd,stop)
	ins(self.bonus,TEXT.getText(text,150+dx,300+dy,font*self.size,style,spd,stop))
end
function player:createLockFX()
	local BK=self.cur.bk
	local t=12-self.gameEnv.lockFX*2

	for i=1,self.r do
		local y=self.curY+i-1
		if without(self.clearedRow,y)then
			y=-30*y
			for j=1,self.c do
				if BK[i][j]then
					ins(self.lockFX,{30*(self.curX+j-2),y,0,t})
				end
			end
		end
	end
end
function player:createDropFX(x,y,w,h)
	ins(self.dropFX,{x,y,w,h,0,13-2*self.gameEnv.dropFX})
end
function player:createMoveFX(dir)
	local T=10-1.5*self.gameEnv.moveFX
	local C=self.cur.color
	local x=self.curX-1
	local y=self.gameEnv.smooth and self.curY+self.dropDelay/self.gameEnv.drop-2 or self.curY-1
	if dir=="left"then
		for i=1,self.r do for j=self.c,1,-1 do
			if self.cur.bk[i][j]then
				ins(self.moveFX,{C,x+j,y+i,0,T})
				break
			end
		end end
	elseif dir=="right"then
		for i=1,self.r do for j=1,self.c do
			if self.cur.bk[i][j]then
				ins(self.moveFX,{C,x+j,y+i,0,T})
				break
			end
		end end
	elseif dir=="down"then
		for j=1,self.c do for i=self.r,1,-1 do
			if self.cur.bk[i][j]then
				ins(self.moveFX,{C,x+j,y+i,0,T})
				break
			end
		end end
	else
		for i=1,self.r do for j=1,self.c do
			if self.cur.bk[i][j]then
				ins(self.moveFX,{C,x+j,y+i,0,T})
			end
		end end
	end
end
function player:createClearingFX(y,spd)
	ins(self.clearFX,{y,0,spd})
end
function player:createBeam(R,send,color)
	local x1,y1,x2,y2
	if self.small then x1,y1=self.centerX,self.centerY
	else x1,y1=self.x+(30*(self.curX+self.sc[2])-30+15+150)*self.size,self.y+(600-30*(self.curY+self.sc[1])+15+70)*self.size
	end
	if R.small then x2,y2=R.centerX,R.centerY
	else x2,y2=R.x+308*R.size,R.y+450*R.size
	end

	wid=int(send^.7*(4+SETTING.atkFX))
	local r,g,b=unpack(SKIN.libColor[color])
	r,g,b=r*2,g*2,b*2

	local a=modeEnv.royaleMode and not(self.human or R.human)and .2 or 1
	sysFX.newAttack(1-SETTING.atkFX*.1,x1,y1,x2,y2,wid,r,g,b,a*(SETTING.atkFX+2)*.0626)
end
--------------------------</FX>--------------------------

--------------------------<Method>--------------------------
function player:RND(a,b)
	return self.randGen:random(a,b)
end

function player:set20G()
	self._20G=true
	if self.AI_mode=="CC"then CC.switch20G(self)end
end
function player:newTask(code,data)
	local L=self.tasks
	ins(L,{
		code=code,
		data=data,
	})
end

function player:solid(x,y)
	if x<1 or x>10 or y<1 then return true end
	if y>#self.field then return false end
	return self.field[y]
	[x]>0--to catch bug (nil[*])
end
function player:ifoverlap(bk,x,y)
	local C=#bk[1]
	if x<1 or x+C>11 or y<1 then return true end
	if y>#self.field then return end
	for i=1,#bk do
		if self.field[y+i-1]then
			for j=1,C do
				if bk[i][j]and self.field[y+i-1][x+j-1]>0 then return true end
			end
		end
	end
end
function player:attack(R,send,time,...)
	if SETTING.atkFX>0 then
		self:createBeam(R,send,time,...)
	end
	R.lastRecv=self
	if R.atkBuffer.sum<20 then
		local B=R.atkBuffer
		if send>20-B.sum then send=20-B.sum end--No more then 20
		local m,k=#B,1
		while k<=m and time>B[k].countdown do k=k+1 end
		for i=m,k,-1 do
			B[i+1]=B[i]
		end
		B[k]={
			pos=self:RND(10),
			amount=send,
			countdown=time,
			cd0=time,
			time=0,
			sent=false,
			lv=min(int(send^.69),5),
		}--Sorted insert(by time)
		B.sum=B.sum+send
		R.stat.recv=R.stat.recv+send
		if R.sound then
			SFX.play(send<4 and"blip_1"or"blip_2",min(send+1,5)*.1)
		end
	end
end

function player:getHolePos()
	if self.garbageBeneath==0 then
		return self:RND(10)
	else
		local p=self:RND(10)
		if self.field[1][p]<=0 then
			return self:RND(10)
		end
		return p
	end
end
function player:garbageRelease()
	local n,flag=1
	while true do
		local A=self.atkBuffer[n]
		if A and A.countdown<=0 and not A.sent then
			self:garbageRise(19+A.lv,A.amount,A.pos)
			self.atkBuffer.sum=self.atkBuffer.sum-A.amount
			A.sent,A.time=true,0
			self.stat.pend=self.stat.pend+A.amount
			n=n+1
			flag=true
		else
			break
		end
	end
	if flag and self.AI_mode=="CC"then CC.updateField(self)end
end
function player:garbageRise(color,amount,pos)
	local _
	local t=self.showTime*2
	for _=1,amount do
		ins(self.field,1,FREEROW.get(color,true))
		ins(self.visTime,1,FREEROW.get(t))
		self.field[1][pos]=0
	end
	self.fieldBeneath=self.fieldBeneath+amount*30
	if self.cur then
		self.curY=self.curY+amount
		self.imgY=self.imgY+amount
	end
	self.garbageBeneath=self.garbageBeneath+amount
	for i=1,#self.clearingRow do
		self.clearingRow[i]=self.clearingRow[i]+amount
	end
	self:freshBlock(false,false)
	for i=1,#self.lockFX do
		_=self.lockFX[i]
		_[2]=_[2]-30*amount--Shift 30px per line cleared
	end
	for i=1,#self.dropFX do
		_=self.dropFX[i]
		_[3],_[5]=_[3]+amount,_[5]+amount
	end
	if #self.field>42 then self:lose()end
end

local invList={2,1,4,3,5,6,7}
function player:pushLine(L,mir)
	local l=#L
	local S=self.gameEnv.skin
	for i=1,l do
		local r=FREEROW.get(0)
		if not mir then
			for j=1,10 do
				r[j]=S[L[i][j]]or 0
			end
		else
			for j=1,10 do
				r[j]=S[invList[L[i][11-j]]]or 0
			end
		end
		ins(self.field,1,r)
		ins(self.visTime,1,FREEROW.get(20))
	end
	self.fieldBeneath=self.fieldBeneath+30*l
	self.curY=self.curY+l
	self.imgY=self.imgY+l
	self:freshBlock(false,false)
end
function player:pushNext(L,mir)
	for i=1,#L do
		self:getNext(mir and invList[L[i]]or L[i])
	end
end

function player:freshTarget()
	if self.atkMode==1 then
		if not self.atking or not self.atking.alive or rnd()<.1 then
			self:changeAtk(randomTarget(self))
		end
	elseif self.atkMode==2 then
		self:changeAtk(self~=GAME.mostBadge and GAME.mostBadge or GAME.secBadge or randomTarget(self))
	elseif self.atkMode==3 then
		self:changeAtk(self~=GAME.mostDangerous and GAME.mostDangerous or GAME.secDangerous or randomTarget(self))
	elseif self.atkMode==4 then
		for i=1,#self.atker do
			if not self.atker[i].alive then
				rem(self.atker,i)
				return
			end
		end
	end
end
function player:changeAtkMode(m)
	if self.atkMode==m then return end
	self.atkMode=m
	if m==1 then
		self:changeAtk(randomTarget(self))
	elseif m==2 or m==3 then
		self:freshTarget()
	elseif m==4 then
		self:changeAtk()
	end
end
function player:changeAtk(R)
	-- if not P.human then R=PLAYERS[1]end--1vALL mode?
	if self.atking then
		local K=self.atking.atker
		for i=1,#K do
			if K[i]==self then
				rem(K,i)
				break
			end
		end
	end
	if R then
		self.atking=R
		ins(R.atker,self)
	else
		self.atking=nil
	end
end
function player:freshBlock(keepGhost,control,system)
	local ENV=self.gameEnv
	if not keepGhost and self.cur then
		self.imgY=min(#self.field+1,self.curY)
		if self._20G or self.keyPressing[7]and ENV.sdarr==0 then
			local _=self.imgY

			--Move ghost to bottom
			while not self:ifoverlap(self.cur.bk,self.curX,self.imgY-1)do
				self.imgY=self.imgY-1
			end

			--Cancel spinLast
			if _~=self.imgY then
				self.spinLast=false
			end

			--Create FX if dropped
			if self.curY>self.imgY then
				if ENV.dropFX and ENV.block and self.curY-self.imgY-self.r>-1 then
					self:createDropFX(self.curX,self.curY-1,self.c,self.curY-self.imgY-self.r+1)
				end
				if ENV.shakeFX then
					self.fieldOff.vy=ENV.shakeFX*.5
				end
				self.curY=self.imgY
			end
		else
			while not self:ifoverlap(self.cur.bk,self.curX,self.imgY-1)do
				self.imgY=self.imgY-1
			end
		end
	end

	if control then
		if ENV.easyFresh then
			local d0=ENV.lock
			if self.lockDelay<d0 and self.freshTime<ENV.freshLimit then
				if not system then
					self.freshTime=self.freshTime+1
				end
				self.lockDelay=d0
				self.dropDelay=ENV.drop
			end
			if self.curY<self.minY then
				self.minY=self.curY
				self.dropDelay=ENV.drop
				self.lockDelay=ENV.lock
			end
		else
			if self.curY<self.minY then
				self.minY=self.curY
				if self.lockDelay<ENV.lock and self.freshTime<ENV.freshLimit then
					self.freshTime=self.freshTime+1
					self.dropDelay=ENV.drop
					self.lockDelay=ENV.lock
				end
			end
		end
	end
end
function player:lock()
	local dest=self.AI_dest
	local has_dest=dest~=nil
	for i=1,self.r do
		local y=self.curY+i-1
		if not self.field[y]then self.field[y],self.visTime[y]=FREEROW.get(0),FREEROW.get(0)end
		for j=1,self.c do
			if self.cur.bk[i][j]then
				self.field[y][self.curX+j-1]=self.cur.color
				self.visTime[y][self.curX+j-1]=self.showTime
				local x=self.curX+j-1
				if dest then
					local original_length=#dest
					for k=1,original_length do
						if x==dest[k][1]and y==dest[k][2]then
							rem(dest, k)
							break
						end
					end
					if #dest~=original_length-1 then
						dest=nil
					end
				end
			end
		end
	end
	if has_dest and not dest then
		CC.updateField(self)
	end
end

local spawnSFX_name={}for i=1,7 do spawnSFX_name[i]="spawn_"..i end
function player:resetBlock()
	local C=self.cur
	local id=C.id
	local face=self.gameEnv.face[id]
	local sc=scs[id][face]
	self.sc=sc					--Spin center
	self.dir=face				--Block direction
	self.r,self.c=#C.bk,#C.bk[1]	--Row/column
	self.curX=int(6-self.c*.5)
	local y=21+ceil(self.fieldBeneath/30)
	self.curY=y
	self.minY=y+sc[2]

	local _=self.keyPressing
	--IMS
	if self.gameEnv.ims and(_[1]and self.movDir==-1 or _[2]and self.movDir==1)and self.moving>=self.gameEnv.das then
		local x=self.curX+self.movDir
		if not self:ifoverlap(C.bk,x,y)then
			self.curX=x
		end
	end

	--IRS
	if self.gameEnv.irs then
		if _[5]then
			self:spin(2,true)
		else
			if _[3]then
				if _[4]then
					self:spin(2,true)
				else
					self:spin(1,true)
				end
			elseif _[4]then
				self:spin(3,true)
			end
		end
	end

	--Spawn SFX
	if self.sound and id<8 then
		SFX.fplay(spawnSFX_name[id],SETTING.spawn)
	end
end

function player:spin(d,ifpre)
	local iki=self.RS[self.cur.id]
	if type(iki)=="table"then
		local idir=(self.dir+d)%4
		local icb=BLOCKS[self.cur.id][idir]
		local isc=scs[self.cur.id][idir]
		local ir,ic=#icb,#icb[1]
		local ix,iy=self.curX+self.sc[2]-isc[2],self.curY+self.sc[1]-isc[1]
		iki=iki[self.dir*10+idir]
		if not iki then
			if self.gameEnv.easyFresh then
				self:freshBlock(false,true)
			end
			SFX.fieldPlay(ifpre and"prerotate"or"rotate",nil,self)
			return
		end
		for test=1,#iki do
			local x,y=ix+iki[test][1],iy+iki[test][2]
			if not self:ifoverlap(icb,x,y)and(self.freshTime<=self.gameEnv.freshLimit or iki[test][2]<0)then
				ix,iy=x,y
				if self.gameEnv.moveFX and self.gameEnv.block then
					self:createMoveFX()
				end
				self.curX,self.curY,self.dir=ix,iy,idir
				self.sc,self.cur.bk=scs[self.cur.id][idir],icb
				self.r,self.c=ir,ic
				self.spinLast=test==2 and 0 or 1
				if not ifpre then
					self:freshBlock(false,true)
				end
				if iki[test][2]>0 and not self.gameEnv.easyFresh then
					self.freshTime=self.freshTime+1
				end

				if self.sound then
					SFX.fieldPlay(ifpre and"prerotate"or self:ifoverlap(self.cur.bk,self.curX,self.curY+1)and self:ifoverlap(self.cur.bk,self.curX-1,self.curY)and self:ifoverlap(self.cur.bk,self.curX+1,self.curY)and"rotatekick"or"rotate",nil,self)
				end
				self.stat.rotate=self.stat.rotate+1
				return
			end
		end
	else
		iki(self,d)
	end
end
function player:hold(ifpre)
	if not self.holded and (ifpre or self.waiting==-1) and self.gameEnv.hold then
		local H,C=self.hd,self.cur
		if not(H or C)then return end

		--Finesse check
		if H and C and H.id==C.id and H.name==C.name then
			self.ctrlCount=self.ctrlCount+1
		elseif self.ctrlCount<=1 then
			self.ctrlCount=0
		end

		self.spinLast=false
		self.spinSeq=0

		self.cur,self.hd=H,C--Swap hold
		H,C=self.hd,self.cur

		if self.next[1]or C then--Make hold available in fixed sequence
			self.holded=self.gameEnv.oncehold
		end

		if H then
			local hid=self.hd.id
			self.hd.bk=BLOCKS[hid][self.gameEnv.face[hid]]
		end
		if not C then
			C=rem(self.next,1)
			self:newNext()
			if C then
				self.cur=C
				self.pieceCount=self.pieceCount+1
				if self.AI_mode=="CC"then
					local next=self.next[self.AIdata.next]
					if next then
						CC.addNext(self.AI_bot,CCblockID[next.id])
					end
				end
			else
				self.holded=false
			end
		end
		if C then
			self:resetBlock()
			self:freshBlock(false,true)
			self.dropDelay=self.gameEnv.drop
			self.lockDelay=self.gameEnv.lock
			self.freshTime=max(self.freshTime-5,0)
			if self:ifoverlap(self.cur.bk,self.curX,self.curY)then self:lock()self:lose()end
		end

		if self.sound then
			SFX.play(ifpre and"prehold"or"hold")
		end
		self.stat.hold=self.stat.hold+1
	end
end

function player:getNext(n)
	local E=self.gameEnv
	ins(self.next,{bk=BLOCKS[n][E.face[n]],id=n,color=E.bone and 17 or E.skin[n],name=n})
end
function player:popNext()--Pop next queue to hand
	self.holded=false
	self.spinLast=false
	self.spinSeq=0
	self.ctrlCount=0

	self.cur=rem(self.next,1)
	self:newNext()
	if self.cur then
		self.pieceCount=self.pieceCount+1
		if self.AI_mode=="CC"then
			local next=self.next[self.AIdata.next]
			if next then
				CC.addNext(self.AI_bot,CCblockID[next.id])
			end
		end

		local _=self.keyPressing
		--IHS
		if _[8]and self.gameEnv.hold and self.gameEnv.ihs then
			self:hold(true)
			_[8]=false
		else
			self:resetBlock()
		end

		self.dropDelay=self.gameEnv.drop
		self.lockDelay=self.gameEnv.lock
		self.freshTime=0

		if self.cur then
			if self:ifoverlap(self.cur.bk,self.curX,self.curY)then
				self:lock()
				self:lose()
			end
			self:freshBlock(false,true,true)
		end

		--IHdS
		if _[6]then
			self.act.hardDrop(self)
			_[6]=false
		end
	end
end

function player:cancel(N)--Cancel Garbage
	local k=0	--Pointer, attack bar selected
	local off=0	--Lines offseted
	local bf=self.atkBuffer
	::R::
	if bf.sum>0 then
		local A
		repeat
			k=k+1
			A=bf[k]
			if not A then return off end
		until not A.sent
		if N>=A.amount then
			local O=A.amount--Cur Offset
			N=N-O
			off=off+O
			bf.sum=bf.sum-O
			A.sent,A.time=true,0
			if N>0 then goto R end
		else
			off=off+N
			A.amount=A.amount-N
			bf.sum=bf.sum-N
		end
	end
	return off
end
do--player.drop(P)--Place piece
	local b2bPoint={50,100,180,1000,1200}
	local b2bATK={3,5,8,12,18}
	local clearSCR={80,200,400}
	local spinSCR={--[blockName][row]
		{200,750,1300,2000},--Z
		{200,750,1300,2000},--S
		{220,700,1300,2000},--L
		{220,700,1300,2000},--J
		{250,800,1400,2000},--T
		{260,900,1700,4000,6000},--O
		{300,1200,1700,4000,6000},--I
		{220,800,2000,3000,8000,26000},--Else
	}
	--B2BMUL:1.2/2.0
	--Techrash:1K;MUL:1.3/1.8
	--Mini*=.6
	local reAtk={0,0,1,1,1,2,2,3,3}
	local reDef={0,1,1,2,3,3,4,4,5}
	local spinVoice={"zspin","sspin","jspin","lspin","tspin","ospin","ispin","zspin","sspin","pspin","qspin","fspin","espin","tspin","uspin","vspin","wspin","xspin","jspin","lspin","rspin","yspin","hspin","nspin","ispin"}
	local clearVoice={"single","double","triple","techrash","pentcrash","hexcrash"}
	local spinSFX={[0]="spin_0","spin_1","spin_2"}
	local clearSFX={"clear_1","clear_2","clear_3"}
	local renSFX={}for i=1,11 do renSFX[i]="ren_"..i end
	local finesseList={
		[1]={
			{1,2,1,0,1,2,2,1},
			{2,2,2,1,1,2,3,2,2},
		},--Z
		[3]={
			{1,2,1,0,1,2,2,1},
			{2,2,3,2,1,2,3,3,2},
			{3,4,3,2,3,4,4,3},
			{2,3,2,1,2,3,3,2,2},
		},--L
		[6]={
			{1,2,2,1,0,1,2,2,1},
		},--O
		[7]={
			{1,2,1,0,1,2,1},
			{2,2,2,2,1,1,2,2,2,2},
		},--I
	}
	finesseList[1][3],finesseList[1][4],finesseList[7][3],finesseList[7][4]=finesseList[1][1],finesseList[1][2],finesseList[7][1],finesseList[7][2]--"2-phase" SZI
	finesseList[2]=finesseList[1]--S=Z
	finesseList[4],finesseList[5]=finesseList[3],finesseList[3]--J=L=T
	function player:drop()
		local _
		local CHN=VOC.getFreeChannel()
		self.dropTime[11]=ins(self.dropTime,1,GAME.frame)--Update speed dial
		local ENV=self.gameEnv
		local STAT=self.stat
		local piece=self.lastPiece

		local cmb=self.combo
		local CB,CX,CY=self.cur,self.curX,self.curY
		local clear--If clear with no line fall
		local cc,gbcc=0,0--Row/garbage-row cleared,full-part
		local atk,exblock=0,0--Attack & extra defense
		local send,off=0,0--Sending lines remain & offset
		local cscore,sendTime=10,0--Score & send Time
		local dospin,mini=0

		piece.id,piece.name=CB.id,CB.name
		self.waiting=ENV.wait

		--Tri-corner spin check
		if self.spinLast then
			if CB.id<6 then
				local x,y=CX+self.sc[2],CY+self.sc[1]
				local c=0
				if self:solid(x-1,y+1)then c=c+1 end
				if self:solid(x+1,y+1)then c=c+1 end
				if c==0 then goto NTC end
				if self:solid(x-1,y-1)then c=c+1 end
				if self:solid(x+1,y-1)then c=c+1 end
				if c>2 then dospin=dospin+2 end
			end
			::NTC::
		end
		--Immovable spin check
		if self:ifoverlap(CB.bk,CX,CY+1)and self:ifoverlap(CB.bk,CX-1,CY)and self:ifoverlap(CB.bk,CX+1,CY)then
			dospin=dospin+2
		end

		--Lock block to field
		self:lock()

		--Clear list of cleared-rows
		if self.clearedRow[1]then self.clearedRow={}end

		--Check line clear
		for i=1,self.r do
			local h=CY+i-2

			--Bomb trigger
			if h>0 and self.field[h]and self.clearedRow[cc]~=h then
				for x=1,self.c do
					if CB.bk[i][x]and self.field[h][CX+x-1]==19 then
						cc=cc+1
						self.clearingRow[cc]=h-cc+1
						self.clearedRow[cc]=h
						break
					end
				end
			end

			h=h+1
			--Row filled
			for x=1,10 do
				if self.field[h][x]<=0 then
					goto notFull
				end
			end
				cc=cc+1
				self.clearingRow[cc]=h-cc+1
				self.clearedRow[cc]=h
			::notFull::
		end

		--Create clearing FX
		if cc>0 and ENV.clearFX then
			local t=7-ENV.clearFX*1
			for i=1,cc do
				self:createClearingFX(self.clearedRow[i],t)
			end
		end

		--Create locking FX
		if ENV.lockFX then
			if cc==0 then
				self:createLockFX()
			else
				_=#self.lockFX
				if _>0 then
					for _=1,_ do
						rem(self.lockFX)
					end
				end
			end
		end

		--Final spin check
		if dospin>0 then
			if cc>0 then
				dospin=dospin+(self.spinLast or 0)
				if dospin<3 then
					mini=CB.id<6 and cc<self.r
				end
			end
		else
			dospin=false
		end

		--Finesse: roof check
		local finesse
		if CB.id>7 then
			finesse=true
		elseif CY<=18 then
			local y0=CY
			local c=self.c
			local B=CB.bk
			for x=1,c do
				local y
				for i=#B,1,-1 do
					if B[i][x]then
						y=i
						goto L1
					end
				end
				goto L2
				::L1::
				if y then
					x=CX+x-1
					for y1=y0+y,#self.field do
						--Roof=finesse
						if self:solid(x,y1)then
							finesse=true
							goto L2
						end
					end
				end
			end
		else
			finesse=true
		end
		::L2::

		--Remove rows need to be cleared
		if cc>0 then
			for i=cc,1,-1 do
				_=self.clearedRow[i]
				if self.field[_][11]then
					self.garbageBeneath=self.garbageBeneath-1
					gbcc=gbcc+1
				end
				FREEROW.discard(rem(self.field,_))
				FREEROW.discard(rem(self.visTime,_))
			end
		end

		--Cancel no-sense clearing FX
		_=#self.clearingRow
		while _>0 and self.clearingRow[_]>#self.field do
			self.clearingRow[_]=nil
			_=_-1
		end
		if self.clearingRow[1]then
			self.falling=ENV.fall
		elseif cc==self.r then
			clear=true
		end

		--Finesse check (control)
		local finePts
		if not finesse then
			if dospin then self.ctrlCount=self.ctrlCount-2 end--Allow 2 more step for roof-less spin
			local id=CB.id
			local d=self.ctrlCount-finesseList[id][self.dir+1][CX]
			finePts=d<=0 and 5 or max(3-d,0)
		else
			finePts=5
		end
		piece.finePts=finePts

		self.stat.finesseRate=self.stat.finesseRate+finePts
		if finePts<5 then
			self.stat.extraPiece=self.stat.extraPiece+1
			if ENV.fineKill then
				self:lose()
			end
			if self.sound then
				if ENV.fineKill then
					SFX.play("finesseError_long",.6)
				elseif ENV.fine then
					SFX.play("finesseError",.8)
				end
			end
		end
		if finePts<=1 then
			self.finesseCombo=0
		else
			self.finesseCombo=self.finesseCombo+1
			if self.finesseCombo>2 then
				self.finesseComboTime=12
			end
			if self.sound then SFX.fieldPlay("lock",nil,self)end
		end

		piece.spin,piece.mini=dospin,false
		piece.pc,piece.hpc=false,false
		piece.special=false
		if cc>0 then--If lines cleared, about 200 lines below
			cmb=cmb+1
			if dospin then
				cscore=(spinSCR[CB.name]or spinSCR[8])[cc]
				if self.b2b>1000 then
					self:showText(text.b3b..text.block[CB.name]..text.spin.." "..text.clear[cc],0,-30,35,"stretch")
					atk=b2bATK[cc]+cc*.5
					exblock=exblock+1
					cscore=cscore*2
					STAT.b3b=STAT.b3b+1
					if self.sound then
						VOC.play("b3b",CHN)
					end
				elseif self.b2b>=50 then
					self:showText(text.b2b..text.block[CB.name]..text.spin.." "..text.clear[cc],0,-30,35,"spin")
					atk=b2bATK[cc]
					cscore=cscore*1.2
					STAT.b2b=STAT.b2b+1
					if self.sound then
						VOC.play("b2b",CHN)
					end
				else
					self:showText(text.block[CB.name]..text.spin.." "..text.clear[cc],0,-30,45,"spin")
					atk=2*cc
				end
				sendTime=20+atk*20
				if mini then
					self:showText(text.mini,0,-80,35,"appear")
					atk=atk*.25
					sendTime=sendTime+60
					cscore=cscore*.5
					self.b2b=self.b2b+b2bPoint[cc]*.5
					if self.sound then
						VOC.play("mini",CHN)
					end
				else
					self.b2b=self.b2b+b2bPoint[cc]
				end
				piece.mini=mini
				piece.special=true
				if self.sound then
					SFX.play(spinSFX[cc]or"spin_3")
					VOC.play(spinVoice[CB.name],CHN)
				end
			elseif cc>=4 then
				cscore=cc==4 and 1000 or cc==5 and 1500 or 2000
				if self.b2b>1000 then
					self:showText(text.b3b..text.clear[cc],0,-30,50,"fly")
					atk=4*cc-10
					sendTime=100
					exblock=exblock+1
					cscore=cscore*1.8
					STAT.b3b=STAT.b3b+1
					if self.sound then
						VOC.play("b3b",CHN)
					end
				elseif self.b2b>=50 then
					self:showText(text.b2b..text.clear[cc],0,-30,50,"drive")
					sendTime=80
					atk=3*cc-7
					cscore=cscore*1.3
					STAT.b2b=STAT.b2b+1
					if self.sound then
						VOC.play("b2b",CHN)
					end
				else
					self:showText(text.clear[cc],0,-30,70,"stretch")
					sendTime=60
					atk=2*cc-4
				end
				self.b2b=self.b2b+cc*100-300
				piece.special=true
			else
				piece.special=false
			end
			if self.sound then
				VOC.play(clearVoice[cc],CHN)
			end

			--PC/HPC bonus
			if clear and #self.field==0 then
				self:showText(text.PC,0,-80,50,"flicker")
				atk=atk*.5+min(8+STAT.pc*2,20)
				exblock=exblock+2
				sendTime=sendTime+120
				if STAT.row+cc>4 then
					self.b2b=1200
					cscore=cscore+300*min(6+STAT.pc,10)
				else
					cscore=cscore+626
				end
				STAT.pc=STAT.pc+1
				if self.sound then
					SFX.play("clear")
					VOC.play("perfect_clear",CHN)
				end
				piece.pc=true
				piece.special=true
			elseif clear and(cc>1 or #self.field==self.garbageBeneath)then
				self:showText(text.HPC,0,-80,50,"fly")
				atk=atk+2
				exblock=exblock+2
				sendTime=sendTime+60
				cscore=cscore+626
				STAT.hpc=STAT.hpc+1
				if self.sound then
					SFX.play("clear")
					VOC.play("half_clear",CHN)
				end
				piece.hpc=true
				piece.special=true
			end

			--Normal clear, reduce B2B point
			if not piece.special then
				self.b2b=max(self.b2b-250,0)
				self:showText(text.clear[cc],0,-30,35,"appear",(8-cc)*.3)
				atk=cc-.5
				sendTime=20+atk*20
				cscore=cscore+clearSCR[cc]
			end

			--Combo bonus
			sendTime=sendTime+25*cmb
			if cmb>1 then
				atk=atk*(1+(cc==1 and .15 or .25)*min(cmb-1,12))
				if cmb>=3 then
					atk=atk+1
				end
				self:showText(text.cmb[min(cmb,21)],0,25,15+min(cmb,15)*5,cmb<10 and"appear"or"flicker")
				cscore=cscore+min(50*cmb,500)*(2*cc-1)
			end

			if self.b2b>1200 then self.b2b=1200 end

			--Bonus atk/def when focused
			if modeEnv.royaleMode then
				local i=min(#self.atker,9)
				if i>1 then
					atk=atk+reAtk[i]
					exblock=exblock+reDef[i]
				end
			end

			--Send Lines
			send=atk
			if send>0 then
				if exblock>0 then
					exblock=int(exblock*(1+self.strength*.25))--Badge Buff
					self:showText("+"..exblock,0,53,20,"fly")
					off=off+self:cancel(exblock)
				end

				send=int(send*(1+self.strength*.25))--Badge Buff
				if send>0 then
					self:showText(send,0,80,35,"zoomout")
					_=self:cancel(send)
					send=send-_
					off=off+_
					if send>0 then
						local T
						if modeEnv.royaleMode then
							if self.atkMode==4 then
								local M=#self.atker
								if M>0 then
									for i=1,M do
										self:attack(self.atker[i],send,CB.color)
									end
								else
									T=randomTarget(self)
								end
							else
								self:freshTarget()
								T=self.atking
							end
						elseif #PLAYERS.alive>1 then
							T=randomTarget(self)
						end
						if T then
							self:attack(T,send,CB.color)
						end
					end
					if self.sound and send>3 then SFX.play("emit",min(send,7)*.1)end
				end
			end

			--Check clearing task
			if self.curMission then
				local t=ENV.mission[self.curMission]
				local success
				if t<5 then
					if piece.row==t and(t==4 or not piece.special)then
						success=true
					end
				elseif t<9 then
					if piece.row==t-4 and piece.spin then
						success=true
					end
				elseif t==9 then
					if piece.pc then
						success=true
					end
				elseif t<90 then
					if piece.row==t%10 and piece.name==int(t/10)and piece.spin then
						success=true
					end
				end
				if success then
					self.curMission=self.curMission+1
					SFX.play("reach")
					if self.curMission>#ENV.mission then
						self.curMission=nil
						self:win("finish")
					end
				elseif ENV.missionKill then
					self:showText(text.missionFailed,0,140,40,"flicker",.5)
					SFX.play("finesseError_long",.6)
					self:lose(true)
				end
			end

			--SFX & Vibrate
			if self.sound then
				SFX.play(clearSFX[cc]or"clear_4")
				SFX.play(renSFX[min(cmb,11)])
				if cmb>14 then SFX.play("ren_mega",(cmb-10)*.1)end
				VIB(cc+1)
			end
		else--No lines clear
			cmb=0

			--Spin bonus
			if dospin then
				self:showText(text.block[CB.name]..text.spin,0,-30,45,"appear")
				self.b2b=self.b2b+20
				if self.sound then
					SFX.play("spin_0")
					VOC.play(spinVoice[CB.name],CHN)
				end
				cscore=30
			end

			if self.b2b>1000 then
				self.b2b=max(self.b2b-40,1000)
			end
			self:garbageRelease()
		end

		self.combo=cmb

		--DropSpeed bonus
		if self._20G then
			cscore=cscore*2
		elseif ENV.drop<1 then
			cscore=cscore*1.5
		elseif ENV.drop<3 then
			cscore=cscore*1.2
		end

		--Speed bonus
		if self.dropSpeed>60 then
			cscore=cscore*(.9+self.dropSpeed/600)
		end

		cscore=int(cscore)
		if ENV.score then
			self:showText(cscore,(self.curX+self.sc[2]-5.5)*30,(10-self.curY-self.sc[1])*30+self.fieldBeneath+self.fieldUp,int(8-120/(cscore+20))*5,"score",2)
		end

		piece.row,piece.dig=cc,gbcc
		piece.score=cscore
		piece.atk,piece.exblock=atk,exblock
		piece.off,piece.send=off,send

		--Update stat
		STAT.score=STAT.score+cscore
		STAT.piece=STAT.piece+1
		STAT.row=STAT.row+cc
		STAT.maxFinesseCombo=max(STAT.maxFinesseCombo,self.finesseCombo)
		STAT.maxCombo=max(STAT.maxCombo,self.combo)
		if atk>0 then
			STAT.atk=STAT.atk+atk
			if send>0 then
				STAT.send=STAT.send+int(send)
			end
			if off>0 then
				STAT.off=STAT.off+off
			end
		end
		if gbcc>0 then
			STAT.dig=STAT.dig+gbcc
			STAT.digatk=STAT.digatk+atk*gbcc/cc
		end
		local n=CB.name
		if dospin then
			_=STAT.spin[n]	_[cc+1]=_[cc+1]+1--Spin[1~25][0~4]
			_=STAT.spins	_[cc+1]=_[cc+1]+1--Spin[0~4]
		elseif cc>0 then
			_=STAT.clear[n]	_[cc]=_[cc]+1--Clear[1~25][1~5]
			_=STAT.clears	_[cc]=_[cc]+1--Clear[1~5]
		end

		--Drop event
		_=ENV.dropPiece
		if _ then _(self)end
	end
end
--------------------------</Methods>--------------------------

--------------------------<Events>--------------------------
local function gameOver()--Save record
	if GAME.replaying then return end
	FILE.saveData()
	local M=CURMODE
	local R=M.getRank
	if R then
		local P=PLAYERS[1]
		R=R(P)--New rank
		if R then
			local r=RANKS[M.name]--Old rank
			local needSave
			if R>r then
				RANKS[M.name]=R
				needSave=true
			end
			if R>0 then
				GAME.rank=R
				if M.unlock then
					for i=1,#M.unlock do
						local m=M.unlock[i]
						local n=MODES[m].name
						if not RANKS[n]then
							RANKS[n]=MODES[m].score and 0 or 6
							needSave=true
						end
					end
				end
			end
			if needSave then
				FILE.saveUnlock()
			end
			local D=M.score(P)
			local L=M.records
			local p=#L--Rank-1
			if p>0 then
				while M.comp(D,L[p])do--If higher rank
					p=p-1
					if p==0 then break end
				end
			end
			if p<10 then
				if p==0 then
					P:showTextF(text.newRecord,0,-100,100,"beat",.5)
				end
				D.date=os.date("%Y/%m/%d %H:%M")
				ins(L,p+1,D)
				if L[11]then L[11]=nil end
				FILE.saveRecord(M.name,L)
			end
		end
	end
end

function player:die()--Called when win/lose,not really die!
	self.alive=false
	self.timing=false
	self.control=false
	self.update=Pupdate_dead
	self.waiting=1e99
	self.b2b=0
	self.tasks={}
	for i=1,#self.atkBuffer do
		self.atkBuffer[i].sent=true
		self.atkBuffer[i].time=0
	end
	for i=1,#self.field do
		for j=1,10 do
			self.visTime[i][j]=min(self.visTime[i][j],20)
		end
	end
end
function player:win(result)
	self:die()
	self.result="WIN"
	if modeEnv.royaleMode then
		self.modeData.event=1
		self:changeAtk()
	end
	if self.human then
		GAME.result=result or"win"
		SFX.play("win")
		VOC.play("win")
		if modeEnv.royaleMode then
			BGM.play("8-bit happiness")
		end
	end
	if CURMODE.id=="custom_puzzle"then
		self:showTextF(text.win,0,0,90,"beat",.4)
	else
		self:showTextF(text.win,0,0,90,"beat",.5,.2)
	end
	if self.human then
		gameOver()
		TASK.new(TICK.autoPause,{0})
		if MARKING then
			self:showTextF(text.marking,0,-226,25,"appear",.4,.0626)
		end
	end
	self:newTask(TICK.finish)
end
function player:lose(force)
	if self.life>0 and not force then
		self.waiting=62
		for _=#self.field,1,-1 do
			FREEROW.discard(self.field[_])
			FREEROW.discard(self.visTime[_])
			self.field[_],self.visTime[_]=nil
		end

		if self.AI_mode=="CC"then
			CC.destroy(self.AI_bot)
			self.hd=nil
			loadAI(self,self.AIdata)
		end

		self.life=self.life-1
		self.fieldBeneath=0
		self.b2b=0
		for i=1,#self.atkBuffer do
			local A=self.atkBuffer[i]
			if not A.sent then
				A.sent=true
				A.time=0
			end
		end
		self.atkBuffer.sum=0

		for i=1,21 do
			self:createClearingFX(i,1.5)
		end
		sysFX.newShade(.7,1,1,1,self.x+150*self.size,self.y+60*self.size,300*self.size,610*self.size)
		sysFX.newRectRipple(.5,self.x+150*self.size,self.y+60*self.size,300*self.size,610*self.size)
		sysFX.newRipple(.5,self.x+(475+25*(self.life<3 and self.life or 0)+12)*self.size,self.y+(665+12)*self.size,20)
		--300+25*i,595
		SFX.play("clear_3")
		SFX.play("emit")

		return
	end
	self:die()
	for i=1,#PLAYERS.alive do
		if PLAYERS.alive[i]==self then
			rem(PLAYERS.alive,i)
			break
		end
	end
	self.result="K.O."
	if modeEnv.royaleMode then
		self:changeAtk()
		self.modeData.event=#PLAYERS.alive+1
		self.strength=0
		if self.lastRecv then
			local A,i=self,0
			repeat
				A,i=A.lastRecv,i+1
			until not A or A.alive or A==self or i==3
			if A and A.alive then
				if self.id==1 or A.id==1 then
					self.killMark=A.id==1
				end
				A.modeData.point,A.badge=A.modeData.point+1,A.badge+self.badge+1
				for j=A.strength+1,4 do
					if A.badge>=royaleData.powerUp[j]then
						A.strength=j
						A.frameColor=frameColor[A.strength]
					end
				end
				self.lastRecv=A
				if self.id==1 or A.id==1 then
					TASK.new(TICK.throwBadge,{A.ai,self,max(3,self.badge)*4})
				end
			end
		else
			self.badge=-1
		end

		freshMostBadge()
		freshMostDangerous()
		if #PLAYERS.alive==royaleData.stage[GAME.stage]then
			royaleLevelup()
		end
		self:showTextF(self.modeData.event,0,120,60,"appear",.26,.9)
	end
	self.gameEnv.keepVisible=self.gameEnv.visible~="show"
	self:showTextF(text.gameover,0,0,60,"appear",.26,.9)
	if self.human then
		GAME.result="gameover"
		SFX.play("fail")
		VOC.play("lose")
		if modeEnv.royaleMode then
			if self.modeData.event==2 then
				BGM.play("hay what kind of feeling")
			else
				BGM.play("end")
			end
		end
		gameOver()
		self:newTask(#PLAYERS>1 and TICK.lose or TICK.finish)
		TASK.new(TICK.autoPause,{0})
		if MARKING then
			self:showTextF(text.marking,0,-226,25,"appear",.4,.0626)
		end
	else
		self:newTask(TICK.lose)
	end
	if #PLAYERS.alive==1 then
		PLAYERS.alive[1]:win()
	end
end

function PLY:check_lineReach()
	if self.stat.row>=self.gameEnv.target then
		self:win("finish")
	end
end
function PLY:check_attackReach()
	if self.stat.atk>=self.gameEnv.target then
		self:win("finish")
	end
end
--------------------------<\Events>--------------------------

--------------------------<Actions>--------------------------
player.act={}
function player.act.moveLeft(P,auto)
	if not auto then
		P.ctrlCount=P.ctrlCount+1
	end
	P.movDir=-1
	if P.keyPressing[9]then
		if P.gameEnv.swap then
			P:changeAtkMode(1)
			P.keyPressing[1]=false
		end
	elseif P.control and P.waiting==-1 then
		if P.cur and not P:ifoverlap(P.cur.bk,P.curX-1,P.curY)then
			if P.gameEnv.moveFX and P.gameEnv.block then
				P:createMoveFX("left")
			end
			P.curX=P.curX-1
			P:freshBlock(false,true)
			if P.sound and P.curY==P.imgY then SFX.play("move")end
			if not auto then P.moving=0 end
			P.spinLast=false
		else
			P.moving=P.gameEnv.das
		end
	else
		P.moving=0
	end
end
function player.act.moveRight(P,auto)
	if not auto then
		P.ctrlCount=P.ctrlCount+1
	end
	P.movDir=1
	if P.keyPressing[9]then
		if P.gameEnv.swap then
			P:changeAtkMode(2)
			P.keyPressing[2]=false
		end
	elseif P.control and P.waiting==-1 then
		if P.cur and not P:ifoverlap(P.cur.bk,P.curX+1,P.curY)then
			if P.gameEnv.moveFX and P.gameEnv.block then
				P:createMoveFX("right")
			end
			P.curX=P.curX+1
			P:freshBlock(false,true)
			if P.sound and P.curY==P.imgY then SFX.play("move")end
			if not auto then P.moving=0 end
			P.spinLast=false
		else
			P.moving=P.gameEnv.das
		end
	else
		P.moving=0
	end
end
function player.act.rotRight(P)
	if P.control and P.waiting==-1 and P.cur then
		P.ctrlCount=P.ctrlCount+1
		P:spin(1)
		P.keyPressing[3]=false
	end
end
function player.act.rotLeft(P)
	if P.control and P.waiting==-1 and P.cur then
		P.ctrlCount=P.ctrlCount+1
		P:spin(3)
		P.keyPressing[4]=false
	end
end
function player.act.rot180(P)
	if P.control and P.waiting==-1 and P.cur then
		P.ctrlCount=P.ctrlCount+2
		P:spin(2)
		P.keyPressing[5]=false
	end
end
function player.act.hardDrop(P)
	if P.keyPressing[9]then
		if P.gameEnv.swap then
			P:changeAtkMode(3)
		end
		P.keyPressing[6]=false
	elseif P.control and P.waiting==-1 and P.cur then
		if P.curY>P.imgY then
			if P.gameEnv.dropFX and P.gameEnv.block and P.curY-P.imgY-P.r>-1 then
				P:createDropFX(P.curX,P.curY-1,P.c,P.curY-P.imgY-P.r+1)
			end
			P.curY=P.imgY
			P.spinLast=false
			if P.gameEnv.shakeFX then
				P.fieldOff.vy=P.gameEnv.shakeFX*.6
			end
			if P.sound then
				SFX.fieldPlay("drop",nil,P)
				VIB(1)
			end
		end
		P.lockDelay=-1
		P:drop()
		P.keyPressing[6]=false
	end
end
function player.act.softDrop(P)
	if P.keyPressing[9]then
		if P.gameEnv.swap then
			P:changeAtkMode(4)
		end
	else
		P.downing=1
		if P.control and P.waiting==-1 and P.cur then
			if P.curY>P.imgY then
				P.curY=P.curY-1
				P:freshBlock(true,true)
				P.spinLast=false
			end
		end
	end
end
function player.act.hold(P)
	if P.control and P.waiting==-1 then
		P:hold()
	end
end
function player.act.func(P)
	P.gameEnv.Fkey(P)
end
function player.act.restart()
	if GAME.frame<240 or GAME.result then
		resetPartGameData()
	else
		LOG.print(text.holdR,20,COLOR.orange)
	end
end
function player.act.insLeft(P,auto)
	if not P.cur then return end
	local x0=P.curX
	while not P:ifoverlap(P.cur.bk,P.curX-1,P.curY)do
		if P.gameEnv.moveFX and P.gameEnv.block then
			P:createMoveFX("left")
		end
		P.curX=P.curX-1
		P:freshBlock(false,true)
	end
	if P.curX~=x0 then
		P.spinLast=false
	end
	if P.gameEnv.shakeFX then
		P.fieldOff.vx=-P.gameEnv.shakeFX*.5
	end
	if auto then
		if P.ctrlCount==0 then P.ctrlCount=1 end
	else
		P.ctrlCount=P.ctrlCount+1
	end
end
function player.act.insRight(P,auto)
	if not P.cur then return end
	local x0=P.curX
	while not P:ifoverlap(P.cur.bk,P.curX+1,P.curY)do
		if P.gameEnv.moveFX and P.gameEnv.block then
			P:createMoveFX("right")
		end
		P.curX=P.curX+1
		P:freshBlock(false,true)
	end
	if P.curX~=x0 then
		P.spinLast=false
	end
	if P.gameEnv.shakeFX then
		P.fieldOff.vx=P.gameEnv.shakeFX*.5
	end
	if auto then
		if P.ctrlCount==0 then P.ctrlCount=1 end
	else
		P.ctrlCount=P.ctrlCount+1
	end
end
function player.act.insDown(P)
	if P.cur and P.curY>P.imgY then
		if P.gameEnv.dropFX and P.gameEnv.block and P.curY-P.imgY-P.r>-1 then
			P:createDropFX(P.curX,P.curY-1,P.c,P.curY-P.imgY-P.r+1)
		end
		if P.gameEnv.shakeFX then
			P.fieldOff.vy=P.gameEnv.shakeFX*.5
		end
		P.curY=P.imgY
		P.lockDelay=P.gameEnv.lock
		P.spinLast=false
		P:freshBlock(true,true)
	end
end
function player.act.down1(P)
	if P.cur and P.curY>P.imgY then
		if P.gameEnv.moveFX and P.gameEnv.block then
			P:createMoveFX("down")
		end
		P.curY=P.curY-1
		P:freshBlock(true,true)
		P.spinLast=false
	end
end
function player.act.down4(P)
	if P.cur and P.curY>P.imgY then
		local y=max(P.curY-4,P.imgY)
		if P.gameEnv.dropFX and P.gameEnv.block and P.curY-y-P.r>-1 then
			P:createDropFX(P.curX,P.curY-1,P.c,P.curY-y-P.r+1)
		end
		P.curY=y
		P:freshBlock(true,true)
		P.spinLast=false
	end
end
function player.act.down10(P)
	if P.cur and P.curY>P.imgY then
		local y=max(P.curY-10,P.imgY)
		if P.gameEnv.dropFX and P.gameEnv.block and P.curY-y-P.r>-1 then
			P:createDropFX(P.curX,P.curY-1,P.c,P.curY-y-P.r+1)
		end
		P.curY=y
		P:freshBlock(true,true)
		P.spinLast=false
	end
end
function player.act.dropLeft(P)
	if not P.cur then return end
	P.act.insLeft(P)
	P.act.hardDrop(P)
end
function player.act.dropRight(P)
	if not P.cur then return end
	P.act.insRight(P)
	P.act.hardDrop(P)
end
function player.act.zangiLeft(P)
	if not P.cur then return end
	P.act.insLeft(P)
	P.act.insDown(P)
	P.act.insRight(P)
	P.act.hardDrop(P)
end
function player.act.zangiRight(P)
	if not P.cur then return end
	P.act.insRight(P)
	P.act.insDown(P)
	P.act.insLeft(P)
	P.act.hardDrop(P)
end
--Give operations a num name
do
	local A=player.act
	local T={
		A.moveLeft	,A.moveRight,	A.rotRight,	A.rotLeft,
		A.rot180	,A.hardDrop,	A.softDrop,	A.hold,
		A.func		,A.restart,		A.insLeft,	A.insRight,
		A.insDown	,A.down1,		A.down4,	A.down10,
		A.dropLeft	,A.dropRight,	A.zangiLeft,A.zangiRight
	}for i=1,20 do A[i]=T[i]end
end
--------------------------</Actions>--------------------------

--------------------------<Generator>--------------------------
function PLY.newDemoPlayer(id,x,y,size)
	local P=newEmptyPlayer(id,x,y,size)
	P.sound=true

	-- rewrite some args
	P.small=false
	P.centerX,P.centerY=P.x+300*P.size,P.y+600*P.size
	P.absFieldX=P.x+150*P.size
	P.absFieldY=P.y+60*P.size
	P.draw=Pdraw_demo
	P.control=true
	P.gameEnv={
		das=10,arr=2,sddas=2,sdarr=2,
		swap=true,

		ghost=SETTING.ghost,
		center=SETTING.center,
		smooth=SETTING.smooth,
		grid=SETTING.grid,
		text=SETTING.text,
		score=SETTING.score,
		lockFX=SETTING.lockFX,
		dropFX=SETTING.dropFX,
		moveFX=SETTING.moveFX,
		clearFX=SETTING.clearFX,
		shakeFX=SETTING.shakeFX,

		drop=1e99,lock=1e99,
		wait=10,fall=20,
		bone=false,
		next=6,
		hold=true,oncehold=true,
		ospin=true,
		sequence="bag",
		bag={1,2,3,4,5,6,7},
		face={0,0,0,0,0,0,0},
		skin=copyTable(SETTING.skin),
		mission=false,

		life=1e99,
		pushSpeed=3,
		block=true,
		noTele=false,
		visible="show",
		freshLimit=1e99,easyFresh=true,

		keyCancel={},
		mindas=0,minarr=0,minsdarr=0,
	}
	applyGameEnv(P)
	prepareSequence(P)
	loadAI(P,{
		type="CC",
		next=5,
		hold=true,
		delay=30,
		delta=4,
		bag="bag",
		node=100000,
	})

	P:popNext()
end
function PLY.newRemotePlayer(id,x,y,size)
	local P=newEmptyPlayer(id,x,y,size)
	P.remote=true

	-- P.updateAction=buildActionFunctionFromActions(P, actions)

	loadGameEnv(P)
	applyGameEnv(P)
	prepareSequence(P)
end
function PLY.newAIPlayer(id,x,y,size,AIdata)
	local P=newEmptyPlayer(id,x,y,size)

	loadGameEnv(P)
	local ENV=P.gameEnv
	ENV.face={0,0,0,0,0,0,0}
	ENV.skin={1,7,11,3,14,4,9}
	if P.small then
		ENV.text=false
		ENV.lockFX=nil
		ENV.dropFX=nil
		ENV.moveFX=nil
		ENV.shakeFX=nil
	end
	applyGameEnv(P)
	prepareSequence(P)
	loadAI(P,AIdata)
end
function PLY.newPlayer(id,x,y,size)
	local P=newEmptyPlayer(id,x,y,size)
	P.human=true
	P.sound=true

	loadGameEnv(P)
	applyGameEnv(P)
	prepareSequence(P)

end
--------------------------</Generator>--------------------------
return PLY