'*************************************
'Space Shuttle (Williams 1984) - IPDB No. 2260
'VPX by bord
'VR Room Space by Rawd
'VR Room Minimal, Cab, and Backglass by Uncle Paulie/Sixtoe
'Physics, Sounds, and Scripting Assistance by rothbauerw
'************************************

Option Explicit
Randomize

' ****************************************************
' OPTIONS
' ****************************************************

'----- Desktop, VR, and Cabinet Options -----

Const VRRoom = 0					'0 = Desktop/Cabinet/FSS, 1 = VR Room Space, 2 = VR Room Minimal
Const cabmode = 0					'0 = Desktop/FSS/VR, 1 = Cabinet Mode, turn off cabinet side rails, lockdown bar, and backbox

'----- Physics and Game Difficulty Options -----

Const Tooeasy = 0					'0 = default operator settings, 1 = liberal operating settings (visuals will be wonky)
Const Rubberizer = 1		     	'1 - rubber dampening version (rothbauerw), 2 - velocity and spin correction version (iaakki)
Const TargetBouncerEnabled = 1 		'0 = normal standup targets, 1 = bouncy targets, 2 = orig TargetBouncer
Const TargetBouncerFactor = 0.7 	'Level of bounces. Recommmended value of 0.7 when TargetBouncerEnabled=1, and 1.1 when TargetBouncerEnabled=2

'----- General Sound Options -----

Const VolumeDial = 0.8		'Values 0-1: global volume multiplier for mechanical sounds 
Const BallRollAmpFactor = 0       		' 0 = no amplification, 1 = 2.5db amplification, 2 = 5db amplification, 3 = 7.5db amplification, 4 = 9db amplification (aka: Tie Fighter)
Const RampRollAmpFactor = 2       		' 0 = no amplification, 1 = 2.5db amplification, 2 = 5db amplification, 3 = 7.5db amplification, 4 = 9db amplification (aka: Tie Fighter)

'----- Shadow Options -----

Const DynamicBallShadowsOn = 1		'0 = no dynamic ball shadow ("triangles" near slings and such), 1 = enable dynamic ball shadow
Const AmbientBallShadowOn = 1		'0 = Static shadow under ball ("flasher" image, like JP's)
									'1 = Moving ball shadow ("primitive" object, like ninuzzu's)
									'2 = flasher image shadow, but it moves like ninuzzu's

' ****************************************************
' END OPTIONS
' ****************************************************

Dim Ballsize,BallMass
BallSize = 50
BallMass = 1

Dim DesktopMode: DesktopMode = Table1.ShowDT

' using table width and height in script slows down the performance
dim tablewidth: tablewidth = Table1.width
dim tableheight: tableheight = Table1.height

On Error Resume Next
ExecuteGlobal GetTextFile("controller.vbs")
If Err Then MsgBox "You need the Controller.vbs file in order to run this table (installed with the VPX package in the scripts folder)"
On Error Goto 0

LoadVPM "01560000", "S11.vbs", 3.36

'********************
'Standard definitions
'********************

Const cGameName = "sshtl_l7"

Const UseSolenoids = 2
Const UseLamps = 0
Const UseGI = 1

Const SSolenoidOn = ""
Const SSolenoidOff = ""
Const SCoin = ""

'******************************************************
' 					TABLE INIT
'******************************************************

Dim ii, collobj, GIObj(30), GICount
Dim SSBall1, SSBall2, SSBall3

Sub Table1_Init
	SetLocale(1033)
	vpmInit Me
	On Error Resume Next
		With Controller
		.GameName = cGameName
		If Err Then MsgBox "Can't start Game" & cGameName & vbNewLine & Err.Description : Exit Sub
		.SplashInfoLine = "Space Shuttle (Williams 1984)" & chr(13) & "by bord"
		.HandleMechanics=0
		.HandleKeyboard=0
		.ShowDMDOnly=1
		.ShowFrame=0
		.ShowTitle=0
		.hidden = 0
		On Error Resume Next
		.Run GetPlayerHWnd
		If Err Then MsgBox Err.Description
		On Error Goto 0
	End With
	On Error Goto 0

	'************  Main Timer init  ******************** 

	PinMAMETimer.Interval = PinMAMEInterval
	PinMAMETimer.Enabled = 1

	'************  Nudging   **************************

	vpmNudge.TiltSwitch=1
	vpmNudge.Sensitivity=1
	vpmNudge.TiltObj=Array(sw25,sw26,sw27,LeftSlingshot,RightSlingshot)

	'************  Trough	**************************
	Set SSBall1 = Slot1.CreateSizedballWithMass(Ballsize/2,Ballmass)
	Set SSBall2 = Slot2.CreateSizedballWithMass(Ballsize/2,Ballmass)
	Set SSBall3 = Slot3.CreateSizedballWithMass(Ballsize/2,Ballmass)
	
	Controller.Switch(10) = 1
	Controller.Switch(11) = 1
	Controller.Switch(12) = 1

	'************  Misc Stuff  ******************	
	'PinCab_Backglass.blenddisablelighting = 1
	centerpostcollide.Collidable=0

	PFGI(False)
	setup_backglass()

End Sub

Sub Table1_Paused:Controller.Pause = 1:End Sub
Sub Table1_unPaused:Controller.Pause = 0:End Sub
Sub Table1_Exit:Controller.Stop:End Sub

'******************************************************
' 						KEYS
'******************************************************

dim plungerpress

Sub Table1_KeyDown(ByVal KeyCode)
	If KeyCode = RightFlipperKey then VR_Cab_ButtonRight.transx = -8 : AlienCount = AlienCount + 1
	If KeyCode = LeftFlipperKey then VR_Cab_ButtonLeft.transx = 8

	If KeyCode = LeftFlipperKey then FlipperActivate LeftFlipper, LFPress
	If keycode = RightFlipperKey Then FlipperActivate RightFlipper, RFPress
	
	'If keycode = RightMagnaSave Then Flash9 true: Setlamp 103, 1
	
	If keycode = PlungerKey Then 
		Plunger.Pullback
		SoundPlungerPull()
		plungerpress = 1
	End If

	if KeyCode = LeftTiltKey Then Nudge 90, 1:SoundNudgeLeft()
	if KeyCode = RightTiltKey Then Nudge 270, 1:SoundNudgeRight()
	if KeyCode = CenterTiltKey Then Nudge 0, 1:SoundNudgeCenter()

	If keycode = keyInsertCoin1 or keycode = keyInsertCoin2 or keycode = keyInsertCoin3 or keycode = keyInsertCoin4 Then
		Select Case Int(rnd*3)
			Case 0: PlaySound ("Coin_In_1"), 0, CoinSoundLevel, 0, 0.25
			Case 1: PlaySound ("Coin_In_2"), 0, CoinSoundLevel, 0, 0.25
			Case 2: PlaySound ("Coin_In_3"), 0, CoinSoundLevel, 0, 0.25
		End Select
	End If

	if keycode = StartGameKey then 
		soundStartButton()
		VR_Cab_startbutton.transy = 5
	End If

	If KeyDownHandler(keycode) Then Exit Sub
End Sub

Sub Table1_KeyUp(ByVal KeyCode)
	If KeyCode = PlungerKey Then
		Plunger.Fire
		plungerpress = 0

		If controller.switch(36) Then
			SoundPlungerReleaseBall()                        'Plunger release sound when there is a ball in shooter lane
		Else
			SoundPlungerReleaseNoBall()                        'Plunger release sound when there is no ball in shooter lane
		End If
	
	End If

	If KeyCode = RightFlipperKey then VR_Cab_ButtonRight.transx = 0
	If KeyCode = LeftFlipperKey then VR_Cab_ButtonLeft.transx = 0		

	If KeyCode = LeftFlipperKey then FlipperDeActivate LeftFlipper, LFPress
	If keycode = RightFlipperKey Then FlipperDeActivate RightFlipper, RFPress

	if keycode=StartGameKey then 		
		VR_Cab_startbutton.transy = 0
	End If

	If KeyUpHandler(keycode) Then Exit Sub
End Sub

'******************************************************
'					SOLENOIDS
'******************************************************

SolCallback(1) = "SolOuthole"							'1 - Outhole
SolCallback(2) = "ReleaseBall"							'2 - Ball Release
SolCallback(3) = "SolLKicker"							'3 - Left Kicker Hole
SolCallback(4) = "SolRKicker"							'4 - Right Kicker Hole
SolCallback(5) = "CenterDropTarget"						'5 - "T" Drop Target
SolCallback(6) = "ThreeBankDrop"						'6 - 3-bank Drop Targets
SolCallback(7) = "PostUp"								'7 - Center Post Up
SolCallback(8) = "PostDown"								'8 - Center Post Down
SolCallback(9) = "Flash9"								'9 - Playfield Space Flasher
SolCallback(10) = "Flash10"								'10 - Playfield Shuttle Flasher
SolCallback(11) = "PFGI"								'11 - GI Relaly
SolCallback(13) = "Diverter"							'13 - Outlane Gate
SolCallback(14) = "SetLamp 103,"						'14 - Backglass Rocket Plume Flasher
solcallback(15) = "SolKnocker" 							'15 - Bell 

SolCallback(sLRFlipper) = "SolRFlipper"
SolCallback(sLLFlipper) = "SolLFlipper"

'******************************************************
'			TROUGH BASED ON NFOZZY'S
'******************************************************

Sub Slot3_Hit():Controller.Switch(10) = 1:UpdateTrough:End Sub
Sub Slot3_UnHit():Controller.Switch(10) = 0:UpdateTrough:End Sub
Sub Slot2_Hit():Controller.Switch(11) = 1:UpdateTrough:End Sub
Sub Slot2_UnHit():Controller.Switch(11) = 0:UpdateTrough:End Sub
Sub Slot1_Hit():Controller.Switch(12) = 1:UpdateTrough:End Sub
Sub Slot1_UnHit():Controller.Switch(12) = 0:UpdateTrough:End Sub

Sub UpdateTrough()
	UpdateTroughTimer.Interval = 300
	UpdateTroughTimer.Enabled = 1
End Sub

Sub UpdateTroughTimer_Timer()
	If Slot1.BallCntOver = 0 Then Slot2.kick 60, 9
	If Slot2.BallCntOver = 0 Then Slot3.kick 60, 9
	Me.Enabled = 0
End Sub

'******************************************************
'				DRAIN & RELEASE
'******************************************************

Sub Drain_Hit()
	RandomSoundDrain drain
	UpdateTrough
	Controller.Switch(9) = 1
End Sub

Sub Drain_UnHit()
	Controller.Switch(9) = 0
End Sub

Sub SolOuthole(enabled)
	If enabled Then 
		Drain.kick 60,20
		'SoundSaucerKick 0, Drain
	End If
End Sub

Sub ReleaseBall(enabled)
	If enabled Then 
		RandomSoundBallRelease Slot1
		Slot1.kick 60, 7
		UpdateTrough
	End If
End Sub

'******************************************************
'				LEFT KICKER
'******************************************************

Sub SolLKicker(enabled)
	If enabled Then
		If Controller.Switch(16) Then
			SoundSaucerKick 1, sw16
		Else
			SoundSaucerKick 0, sw16
		End If
		sw16.kick 183 + Rnd*4, 16 + Rnd*4
		Controller.Switch(16) = 0
	End If
End Sub

Sub sw16_hit()
	Controller.Switch(16) = 1
	SoundSaucerLock	
End sub

'******************************************************
'				RIGHT KICKER
'******************************************************

Sub SolRKicker(enabled)
	If enabled Then
		If Controller.Switch(24) Then
			SoundSaucerKick 1, sw24
		Else
			SoundSaucerKick 0, sw24
		End If
		sw24.kick 170 + Rnd*4, 16 + Rnd*4
		Controller.Switch(24) = 0
	End If
End Sub

Sub sw24_hit()
	Controller.Switch(24) = 1
	SoundSaucerLock
End sub

'******************************************************
'				DROP TARGETS
'******************************************************

Sub CenterDropTarget(enabled)
	if enabled then
		RandomSoundDropTargetReset psw20
		DTRaise 20
	end if
End Sub

Sub ThreeBankDrop(enabled)
	if enabled then
		RandomSoundDropTargetReset psw34
		DTRaise 33
		DTRaise 34
		DTRaise 35
	end if
End Sub

'******************************************************
' 						CENTER POST
'******************************************************

Dim CenterPostDir, MovePostSpeed
CenterPostCollide.timerinterval = 8
MovePostSpeed = 5

Sub CenterPostCollide_timer()
	CenterPost.transz = CenterPost.transz + CenterPostDir*MovePostSpeed/5

	if CenterPost.transz > 13 Then
		centerpostcollide.collidable = True
	Else
		centerpostcollide.collidable = False	
	End If

	If CenterPost.transz < 25 Then lp1.state = 0

	If CenterPost.transz < 0.1 Then
		CenterPost.transz = 0
		me.timerenabled = False
	End If
	If CenterPost.transz > 24.9 Then
		CenterPost.transz = 25
		me.timerenabled = False
	End If
	cprod.transz = centerpost.transz
End Sub

Sub PostUp(Enabled)
    If Enabled Then
		CenterPostDir = 1
		CenterPostcollide.timerenabled = true
		SoundSaucerKick 0, centerpost		
    End If
End Sub
 
Sub PostDown(Enabled)
    If Enabled Then
		CenterPostDir = -1
		CenterPostcollide.timerenabled = true
		Playsoundat "soloff", centerpost
    End If
End Sub

'******************************************************
'					DIVERTER
'******************************************************

Sub Diverter(Enabled)
 	If Enabled then
		Playsoundat "soloff", centerpost
		bottomgate.rotatetoend
	Else
		Playsoundat "soloff", centerpost
		bottomgate.rotatetostart
 	end if
End Sub

'******************************************************
'					KNOCKER (BELL)
'******************************************************

'Modified to play bell instead of knocker
Sub SolKnocker(Enabled)
	If enabled Then
		KnockerSolenoid 'Add knocker position object
	End If
End Sub

'******************************************************
'					BUMPERS
'******************************************************

Sub sw25_hit
	vpmTimer.PulseSw(25)
	RandomSoundBumperTop p25
	bumperskirt001.roty=skirtAY(me,Activeball)
	bumperskirt001.rotx=skirtAX(me,Activeball)
	me.timerinterval = 150
	me.timerenabled=1
End Sub

sub sw25_timer
	bumperskirt001.rotx=0
	bumperskirt001.roty=0
	me.timerenabled=0
end sub

Sub sw26_hit
	vpmTimer.PulseSw(26)
	RandomSoundBumperMiddle p26
	bumperskirt002.roty=skirtAY(me,Activeball)
	bumperskirt002.rotx=skirtAX(me,Activeball)
	me.timerinterval = 150
	me.timerenabled=1
End Sub

sub sw26_timer
	bumperskirt002.rotx=0
	bumperskirt002.roty=0
	me.timerenabled=0
end sub

Sub sw27_hit
	vpmTimer.PulseSw(27)
	RandomSoundBumperBottom p27
	bumperskirt003.roty=skirtAY(me,Activeball)
	bumperskirt003.rotx=skirtAX(me,Activeball)
	me.timerinterval = 150
	me.timerenabled=1
End Sub

sub sw27_timer
	bumperskirt003.rotx=0
	bumperskirt003.roty=0
	me.timerenabled=0
end sub

'******************************************************
'			SKIRT ANIMATION FUNCTIONS
'******************************************************
' NOTE: set bumper object timer to around 150-175 in order to be able
' to actually see the animation, adjust to your liking

'Const PI = 3.1415926
Const SkirtTilt=3		'angle of skirt tilting in degrees

Function SkirtAX(bumper, bumperball)
	skirtAX=cos(skirtA(bumper,bumperball))*(SkirtTilt)		'x component of angle
	if (bumper.y<bumperball.y) then	skirtAX=skirtAX*-1	'adjust for ball hit bottom half
End Function

Function SkirtAY(bumper, bumperball)
	skirtAY=sin(skirtA(bumper,bumperball))*(SkirtTilt)		'y component of angle
	if (bumper.x>bumperball.x) then	skirtAY=skirtAY*-1	'adjust for ball hit left half
End Function

Function SkirtA(bumper, bumperball)
	dim hitx, hity, dx, dy
	hitx=bumperball.x
	hity=bumperball.y

	dy=Abs(hity-bumper.y)					'y offset ball at hit to center of bumper
	if dy=0 then dy=0.0000001
	dx=Abs(hitx-bumper.x)					'x offset ball at hit to center of bumper
	skirtA=(atn(dx/dy)) '/(PI/180)			'angle in radians to ball from center of Bumper1
End Function


'******************************************************
'				SLINGSHOTS
'******************************************************

Dim RStep, Lstep

Sub RightSlingShot_Slingshot
	vpmTimer.PulseSw 40
    RandomSoundSlingshotRight rsling
    RSling.Visible = 0
    RSling1.Visible = 1
    sling1.rotx = 16
    RStep = 0
    RightSlingShot.TimerEnabled = 1
End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 3:RSLing1.Visible = 0:RSLing2.Visible = 1:sling1.rotx = 10
        Case 4:RSLing2.Visible = 0:RSLing.Visible = 1:sling1.rotx = 0:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

Sub LeftSlingShot_Slingshot
	vpmTimer.PulseSw 39
    RandomSoundSlingshotLeft lsling
    LSling.Visible = 0
    LSling1.Visible = 1
    sling2.rotx = 20
    LStep = 0
    LeftSlingShot.TimerEnabled = 1
End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 3:LSLing1.Visible = 0:LSLing2.Visible = 1:sling2.rotx = 10
        Case 4:LSLing2.Visible = 0:LSLing.Visible = 1:sling2.rotx = 0:LeftSlingShot.TimerEnabled = 0
    End Select
    LStep = LStep + 1
End Sub

'******************************************************
'				SWITCHES
'******************************************************

Sub bottomgate_Collide
	RandomSoundFlipperBallGuide
End Sub


'Drop Targets
Sub Sw20_Hit:DTHit 20:End Sub
Sub Sw33_Hit:DTHit 33:End Sub
Sub Sw34_Hit:DTHit 34:End Sub
Sub Sw35_Hit:DTHit 35:End Sub

'Stand Up Targets
Sub Tsw17_Hit:STHit 17: End Sub
Sub Tsw18_Hit:STHit 18: End Sub
Sub Tsw19_Hit:STHit 19: End Sub
Sub Tsw21_Hit:STHit 21: End Sub
Sub Tsw22_Hit:STHit 22: End Sub
Sub Tsw23_Hit:STHit 23: End Sub
Sub Tsw38_Hit:STHit 38: End Sub

'Wire Triggers
Sub sw13_Hit:vpmTimer.PulseSw 13:End Sub
Sub sw14_Hit:vpmTimer.PulseSw 14:End Sub
Sub sw15_Hit:vpmTimer.PulseSw 15:End Sub
Sub sw28_Hit:vpmTimer.PulseSw 28:End Sub
Sub sw29_Hit:vpmTimer.PulseSw 29:End Sub
Sub sw30_Hit:vpmTimer.PulseSw 30:End Sub
Sub sw31_Hit:vpmTimer.PulseSw 31:End Sub
Sub sw36_Hit:vpmTimer.PulseSw 36:End Sub

'Spinner
Sub sw37_Spin():VPMTimer.PulseSw 37:SoundSpinner sw37:End Sub

'Ramp Switches
Sub sw32_Hit : vpmTimer.PulseSw(32): End Sub
Sub sw45_Hit : vpmTimer.PulseSw(45) : End Sub

'Rubber Switchtes
Sub sw42_Hit:vpmTimer.PulseSw 42:End Sub
Sub sw43_Hit:vpmTimer.PulseSw 43:End Sub
Sub sw44_Hit:vpmTimer.PulseSw 44:End Sub
Sub sw46_Hit:vpmTimer.PulseSw 46:End Sub
Sub sw47_Hit:vpmTimer.PulseSw 47:End Sub
Sub sw48_Hit:vpmTimer.PulseSw 48:End Sub

'******************************************************
'                DROP TARGETS INITIALIZATION
'******************************************************
Class DropTarget
	Private m_primary, m_secondary, m_prim, m_sw, m_animate, m_isDropped
  
	Public Property Get Primary(): Set Primary = m_primary: End Property
	Public Property Let Primary(input): Set m_primary = input: End Property
  
	Public Property Get Secondary(): Set Secondary = m_secondary: End Property
	Public Property Let Secondary(input): Set m_secondary = input: End Property
  
	Public Property Get Prim(): Set Prim = m_prim: End Property
	Public Property Let Prim(input): Set m_prim = input: End Property
  
	Public Property Get Sw(): Sw = m_sw: End Property
	Public Property Let Sw(input): m_sw = input: End Property
  
	Public Property Get Animate(): Animate = m_animate: End Property
	Public Property Let Animate(input): m_animate = input: End Property
  
	Public Property Get IsDropped(): IsDropped = m_isDropped: End Property
	Public Property Let IsDropped(input): m_isDropped = input: End Property
  
	Public default Function init(primary, secondary, prim, sw, animate, isDropped)
	  Set m_primary = primary
	  Set m_secondary = secondary
	  Set m_prim = prim
	  m_sw = sw
	  m_animate = animate
	  m_isDropped = isDropped
  
	  Set Init = Me
	End Function
End Class

'Set array with drop target objects

dim DT20, DT33, DT34, DT35
'
'DropTargetvar = Array(primary, secondary, prim, swtich, animate)
'         primary:                         primary target wall to determine drop
'        secondary:                        wall used to simulate the ball striking a bent or offset target after the initial Hit
'        prim:                                primitive target used for visuals and animation
'                                                        IMPORTANT!!! 
'                                                        rotz must be used for orientation
'                                                        rotx to bend the target back
'                                                        transz to move it up and down
'                                                        the pivot point should be in the center of the target on the x, y and at or below the playfield (0) on z
'        switch:                                ROM switch number
'        animate:                        Arrary slot for handling the animation instrucitons, set to 0
'
'        Values for annimate: 1 - bend target (hit to primary), 2 - drop target (hit to secondary), 3 - brick target (high velocity hit to secondary), -1 - raise target 

' Center Bank
Set DT20 = (new DropTarget)(sw20, sw20y, psw20, 20, 0, false)

' Left Bank
Set DT33 = (new DropTarget)(sw33, sw33y, psw33, 33, 0, false)
Set DT34 = (new DropTarget)(sw34, sw34y, psw34, 34, 0, false)
Set DT35 = (new DropTarget)(sw35, sw35y, psw35, 35, 0, false)

'Add all the Drop Target Arrays to Drop Target Animation Array
' DTAnimationArray = Array(DT1, DT2, ....)
Dim DTArray
DTArray = Array(DT20, DT33, DT34, DT35)

'Configure the behavior of Drop Targets.
Const DTDropSpeed = 110							'in milliseconds
Const DTDropUpSpeed = 40						'in milliseconds
Const DTDropUnits = 49							'VP units primitive drops
Const DTDropUpUnits = 5							'VP units primitive raises above the up position on drops up
Const DTMaxBend = 8								'max degrees primitive rotates when hit
Const DTDropDelay = 20							'time in milliseconds before target drops (due to friction/impact of the ball)
Const DTRaiseDelay = 40							'time in milliseconds before target drops back to normal up position after the solendoid fires to raise the target
Const DTBrickVel = 30							'velocity at which the target will brick, set to '0' to disable brick

Const DTEnableBrick = 0							'Set to 0 to disable bricking, 1 to enable bricking
Const DTHitSound = "targethit"					'Drop Target Hit sound
Const DTDropSound = "DTDrop"					'Drop Target Drop sound
Const DTResetSound = "DTReset"					'Drop Target reset sound

Const DTMass = 0.2								'Mass of the Drop Target (between 0 and 1), higher values provide more resistance


'******************************************************
'				DROP TARGETS FUNCTIONS
'******************************************************

Sub DTHit(switch)
	Dim i
	i = DTArrayID(switch)

	PlayTargetSound
	DTArray(i).animate =  DTCheckBrick(Activeball,DTArray(i).prim)
	If DTArray(i).animate = 1 or DTArray(i).animate = 3 or DTArray(i).animate = 4 Then
		DTBallPhysics Activeball, DTArray(i).prim.rotz, DTMass
	End If
	DoDTAnim
End Sub

Sub DTRaise(switch)
	Dim i
	i = DTArrayID(switch)

	DTArray(i).animate = -1
	DoDTAnim
End Sub

Sub DTDrop(switch)
	Dim i
	i = DTArrayID(switch)

	DTArray(i).animate = 1
	DoDTAnim
End Sub

Function DTArrayID(switch)
	Dim i
	For i = 0 to uBound(DTArray) 
		If DTArray(i).sw = switch Then DTArrayID = i:Exit Function 
	Next
End Function

sub DTBallPhysics(aBall, angle, mass)
	dim rangle,bangle,calc1, calc2, calc3
	rangle = (angle - 90) * 3.1416 / 180
	bangle = atn2(cor.ballvely(aball.id),cor.ballvelx(aball.id))

	calc1 = cor.BallVel(aball.id) * cos(bangle - rangle) * (aball.mass - mass) / (aball.mass + mass)
	calc2 = cor.BallVel(aball.id) * sin(bangle - rangle) * cos(rangle + 4*Atn(1)/2)
	calc3 = cor.BallVel(aball.id) * sin(bangle - rangle) * sin(rangle + 4*Atn(1)/2)

	aBall.velx = calc1 * cos(rangle) + calc2
	aBall.vely = calc1 * sin(rangle) + calc3
End Sub

'Check if target is hit on it's face or sides and whether a 'brick' occurred
Function DTCheckBrick(aBall, dtprim) 
	dim bangle, bangleafter, rangle, rangle2, Xintersect, Yintersect, cdist, perpvel, perpvelafter, paravel, paravelafter
	rangle = (dtprim.rotz - 90) * 3.1416 / 180
	rangle2 = dtprim.rotz * 3.1416 / 180
	bangle = atn2(cor.ballvely(aball.id),cor.ballvelx(aball.id))
	bangleafter = Atn2(aBall.vely,aball.velx)

	Xintersect = (aBall.y - dtprim.y - tan(bangle) * aball.x + tan(rangle2) * dtprim.x) / (tan(rangle2) - tan(bangle))
	Yintersect = tan(rangle2) * Xintersect + (dtprim.y - tan(rangle2) * dtprim.x)

	cdist = Distance(dtprim.x, dtprim.y, Xintersect, Yintersect)

	perpvel = cor.BallVel(aball.id) * cos(bangle-rangle)
	paravel = cor.BallVel(aball.id) * sin(bangle-rangle)

	perpvelafter = BallSpeed(aBall) * cos(bangleafter - rangle) 
	paravelafter = BallSpeed(aBall) * sin(bangleafter - rangle)

	If perpvel > 0 and  perpvelafter <= 0 Then
		If DTEnableBrick = 1 and  perpvel > DTBrickVel and DTBrickVel <> 0 and cdist < 8 Then
			DTCheckBrick = 3
		Else
			DTCheckBrick = 1
		End If
	ElseIf perpvel > 0 and ((paravel > 0 and paravelafter > 0) or (paravel < 0 and paravelafter < 0)) Then
		DTCheckBrick = 4
	Else 
		DTCheckBrick = 0
	End If
End Function

Sub DoDTAnim()
	Dim i
	For i=0 to Ubound(DTArray)
		DTArray(i).animate = DTAnimate(DTArray(i).primary,DTArray(i).secondary,DTArray(i).prim,DTArray(i).sw,DTArray(i).animate)
	Next
End Sub

Function DTAnimate(primary, secondary, prim, switch,  animate)
	dim transz
	Dim animtime, rangle

	rangle = prim.rotz * 3.1416 / 180

	DTAnimate = animate

	if animate = 0  Then
		primary.uservalue = 0
		DTAnimate = 0
		Exit Function
	Elseif primary.uservalue = 0 then 
		primary.uservalue = gametime
	end if

	animtime = gametime - primary.uservalue

	If (animate = 1 or animate = 4) and animtime < DTDropDelay Then
		primary.collidable = 0
		If animate = 1 then secondary.collidable = 1 else secondary.collidable= 0
		prim.rotx = DTMaxBend * cos(rangle)
		prim.roty = DTMaxBend * sin(rangle)
		DTAnimate = animate
		Exit Function
	elseif (animate = 1 or animate = 4) and animtime > DTDropDelay Then
		primary.collidable = 0
		If animate = 1 then secondary.collidable = 1 else secondary.collidable= 0
		prim.rotx = DTMaxBend * cos(rangle)
		prim.roty = DTMaxBend * sin(rangle)
		animate = 2
		SoundDropTargetDrop prim
	End If

	if animate = 2 Then
		transz = (animtime - DTDropDelay)/DTDropSpeed *  DTDropUnits * -1
		if prim.transz > -DTDropUnits  Then
			prim.transz = transz
		end if

		prim.rotx = DTMaxBend * cos(rangle)/2
		prim.roty = DTMaxBend * sin(rangle)/2

		if prim.transz <= -DTDropUnits Then 
			prim.transz = -DTDropUnits
			prim.blenddisablelighting = 0.2
			secondary.collidable = 0
			controller.Switch(Switch) = 1
			primary.uservalue = 0
			DTAnimate = 0
			Exit Function
		Else
			DTAnimate = 2
			Exit Function
		end If 
	End If

	If animate = 3 and animtime < DTDropDelay Then
		primary.collidable = 0
		secondary.collidable = 1
		prim.rotx = DTMaxBend * cos(rangle)
		prim.roty = DTMaxBend * sin(rangle)
	elseif animate = 3 and animtime > DTDropDelay Then
		primary.collidable = 1
		secondary.collidable = 0
		prim.rotx = 0
		prim.roty = 0
		primary.uservalue = 0
		DTAnimate = 0
		Exit Function
	End If

	if animate = -1 Then
		transz = (1 - (animtime/DTDropUpSpeed)) *  DTDropUnits * -1

		If prim.transz = -DTDropUnits Then
			Dim BOT, b
			BOT = GetBalls

			For b = 0 to UBound(BOT)
				If InRotRect(BOT(b).x,BOT(b).y,prim.x, prim.y, prim.rotz, -25,-10,25,-10,25,25,-25,25) and BOT(b).z < prim.z+DTDropUnits+25 Then
                                        BOT(b).velz = 20
                                End If
			Next
		End If

		if prim.transz < 0 Then
			prim.blenddisablelighting = 0.35
			prim.transz = transz
		elseif transz > 0 then
			prim.transz = transz
		end if

		if prim.transz > DTDropUpUnits then 
			prim.transz = DTDropUpUnits
			DTAnimate = -2
			prim.rotx = 0
			prim.roty = 0
			primary.uservalue = gametime
		end if
		primary.collidable = 0
		secondary.collidable = 1
		controller.Switch(Switch) = 0

	End If

	if animate = -2 and animtime > DTRaiseDelay Then
		prim.transz = (animtime - DTRaiseDelay)/DTDropSpeed *  DTDropUnits * -1 + DTDropUpUnits 
		if prim.transz < 0 then
			prim.transz = 0
			primary.uservalue = 0
			DTAnimate = 0

			primary.collidable = 1
			secondary.collidable = 0
		end If 
	End If
End Function


'******************************************************
'                DROP TARGET
'                SUPPORTING FUNCTIONS 
'******************************************************

' Used for drop targets
'*** Determines if a Points (px,py) is inside a 4 point polygon A-D in Clockwise/CCW order
Function InRect(px,py,ax,ay,bx,by,cx,cy,dx,dy)
	Dim AB, BC, CD, DA
	AB = (bx*py) - (by*px) - (ax*py) + (ay*px) + (ax*by) - (ay*bx)
	BC = (cx*py) - (cy*px) - (bx*py) + (by*px) + (bx*cy) - (by*cx)
	CD = (dx*py) - (dy*px) - (cx*py) + (cy*px) + (cx*dy) - (cy*dx)
	DA = (ax*py) - (ay*px) - (dx*py) + (dy*px) + (dx*ay) - (dy*ax)

	If (AB <= 0 AND BC <=0 AND CD <= 0 AND DA <= 0) Or (AB >= 0 AND BC >=0 AND CD >= 0 AND DA >= 0) Then
		InRect = True
	Else
		InRect = False       
	End If
End Function

Function InRotRect(ballx,bally,px,py,angle,ax,ay,bx,by,cx,cy,dx,dy)
    Dim rax,ray,rbx,rby,rcx,rcy,rdx,rdy
    Dim rotxy
    rotxy = RotPoint(ax,ay,angle)
    rax = rotxy(0)+px : ray = rotxy(1)+py
    rotxy = RotPoint(bx,by,angle)
    rbx = rotxy(0)+px : rby = rotxy(1)+py
    rotxy = RotPoint(cx,cy,angle)
    rcx = rotxy(0)+px : rcy = rotxy(1)+py
    rotxy = RotPoint(dx,dy,angle)
    rdx = rotxy(0)+px : rdy = rotxy(1)+py

    InRotRect = InRect(ballx,bally,rax,ray,rbx,rby,rcx,rcy,rdx,rdy)
End Function

Function RotPoint(x,y,angle)
    dim rx, ry
    rx = x*dCos(angle) - y*dSin(angle)
    ry = x*dSin(angle) + y*dCos(angle)
    RotPoint = Array(rx,ry)
End Function

'******************************************************
'		STAND-UP TARGET INITIALIZATION
'******************************************************

Class StandupTarget
  Private m_primary, m_prim, m_sw, m_animate

  Public Property Get Primary(): Set Primary = m_primary: End Property
  Public Property Let Primary(input): Set m_primary = input: End Property

  Public Property Get Prim(): Set Prim = m_prim: End Property
  Public Property Let Prim(input): Set m_prim = input: End Property

  Public Property Get Sw(): Sw = m_sw: End Property
  Public Property Let Sw(input): m_sw = input: End Property

  Public Property Get Animate(): Animate = m_animate: End Property
  Public Property Let Animate(input): m_animate = input: End Property

  Public default Function init(primary, prim, sw, animate)
    Set m_primary = primary
    Set m_prim = prim
    m_sw = sw
    m_animate = animate

    Set Init = Me
  End Function
End Class

'Define a variable for each stand-up target
Dim ST17, ST18, ST19, ST21, ST22, ST23, ST38

'Set array with stand-up target objects
'
'StandupTargetvar = Array(primary, prim, swtich)
' 	primary: 			vp target to determine target hit
'	prim:				primitive target used for visuals and animation
'							IMPORTANT!!! 
'							transy must be used to offset the target animation
'	switch:				ROM switch number
'	animate:			Arrary slot for handling the animation instrucitons, set to 0

Set ST17 = (new StandupTarget)(tsw17, primt17,17, 0)
Set ST18 = (new StandupTarget)(tsw18, primt18,18, 0)
Set ST19 = (new StandupTarget)(tsw19, primt19,19, 0)
Set ST21 = (new StandupTarget)(tsw21, primt21,21, 0)
Set ST22 = (new StandupTarget)(tsw22, primt22,22, 0)
Set ST23 = (new StandupTarget)(tsw23, primt23,23, 0)
Set ST38 = (new StandupTarget)(tsw38, primt38,38, 0)

'Add all the Stand-up Target Arrays to Stand-up Target Animation Array
' STAnimationArray = Array(ST1, ST2, ....)
Dim STArray
STArray = Array(ST17, ST18, ST19, ST21, ST22, ST23, ST38)

'Configure the behavior of Stand-up Targets
Const STAnimStep =  1.5 				'vpunits per animation step (control return to Start)
Const STMaxOffset = 9 			'max vp units target moves when hit
Const STHitSound = "targethit"	'Stand-up Target Hit sound

Const STMass = 0.2				'Mass of the Stand-up Target (between 0 and 1), higher values provide more resistance

'******************************************************
'				STAND-UP TARGETS FUNCTIONS
'******************************************************

Sub STHit(switch)
	Dim i
	i = STArrayID(switch)

	PlayTargetSound
	STArray(i).animate =  STCheckHit(Activeball,STArray(i).primary)

	If STArray(i).animate <> 0 Then
		DTBallPhysics Activeball, STArray(i).primary.orientation, STMass
	End If
	DoSTAnim
End Sub

Function STArrayID(switch)
	Dim i
	For i = 0 to uBound(STArray) 
		If STArray(i).sw = switch Then STArrayID = i:Exit Function 
	Next
End Function

'Check if target is hit on it's face
Function STCheckHit(aBall, target) 
	dim bangle, bangleafter, rangle, rangle2, perpvel, perpvelafter, paravel, paravelafter
	rangle = (target.orientation - 90) * 3.1416 / 180	
	bangle = atn2(cor.ballvely(aball.id),cor.ballvelx(aball.id))
	bangleafter = Atn2(aBall.vely,aball.velx)

	perpvel = cor.BallVel(aball.id) * cos(bangle-rangle)
	paravel = cor.BallVel(aball.id) * sin(bangle-rangle)

	perpvelafter = BallSpeed(aBall) * cos(bangleafter - rangle) 
	paravelafter = BallSpeed(aBall) * sin(bangleafter - rangle)

	If perpvel > 0 and  perpvelafter <= 0 Then
		STCheckHit = 1
	ElseIf perpvel > 0 and ((paravel > 0 and paravelafter > 0) or (paravel < 0 and paravelafter < 0)) Then
		STCheckHit = 1
	Else 
		STCheckHit = 0
	End If
End Function

Sub DoSTAnim()
	Dim i
	For i=0 to Ubound(STArray)
		STArray(i).animate = STAnimate(STArray(i).primary,STArray(i).prim,STArray(i).sw,STArray(i).animate)
	Next
End Sub

Function STAnimate(primary, prim, switch,  animate)
	Dim animtime

	STAnimate = animate

	if animate = 0  Then
		primary.uservalue = 0
		STAnimate = 0
		Exit Function
	Elseif primary.uservalue = 0 then 
		primary.uservalue = gametime
	end if

	animtime = gametime - primary.uservalue

	If animate = 1 Then
		primary.collidable = 0
		prim.transy = -STMaxOffset
		vpmTimer.PulseSw switch
		STAnimate = 2
		Exit Function
	elseif animate = 2 Then
		prim.transy = prim.transy + STAnimStep
		If prim.transy >= 0 Then
			prim.transy = 0
			primary.collidable = 1
			STAnimate = 0
			Exit Function
		Else 
			STAnimate = 2
		End If
	End If	
End Function

'******************************************************
'						FLIPPERS
'******************************************************
Const ReflipAngle = 20

Sub SolLFlipper(Enabled)
	If Enabled Then
		LF.Fire
		If leftflipper.currentangle < leftflipper.endangle + ReflipAngle Then 
			RandomSoundReflipUpLeft LeftFlipper
		Else 
			SoundFlipperUpAttackLeft LeftFlipper
			RandomSoundFlipperUpLeft LeftFlipper
		End If   
	Else
		LeftFlipper.RotateToStart
		If LeftFlipper.currentangle < LeftFlipper.startAngle - 5 Then
			RandomSoundFlipperDownLeft LeftFlipper
		End If
		FlipperLeftHitParm = FlipperUpSoundLevel
	End If
End Sub
 
Sub SolRFlipper(Enabled)
	If Enabled Then
		RF.Fire 'rightflipper.rotatetoend
		If rightflipper.currentangle > rightflipper.endangle - ReflipAngle Then
			RandomSoundReflipUpRight RightFlipper
		Else 
			SoundFlipperUpAttackRight RightFlipper
			RandomSoundFlipperUpRight RightFlipper
		End If
	Else
		RightFlipper.RotateToStart
		If RightFlipper.currentangle > RightFlipper.startAngle + 5 Then
			RandomSoundFlipperDownRight RightFlipper
		End If        
		FlipperRightHitParm = FlipperUpSoundLevel
	End If
End Sub

'******************************************************
'                        FLIPPER TRICKS
'******************************************************

RightFlipper.timerinterval=1
Rightflipper.timerenabled=True

sub RightFlipper_timer()
	FlipperTricks LeftFlipper, LFPress, LFCount, LFEndAngle, LFState
	FlipperTricks RightFlipper, RFPress, RFCount, RFEndAngle, RFState
	FlipperNudge RightFlipper, RFEndAngle, RFEOSNudge, LeftFlipper, LFEndAngle
	FlipperNudge LeftFlipper, LFEndAngle, LFEOSNudge,  RightFlipper, RFEndAngle
end sub

Dim LFEOSNudge, RFEOSNudge

Sub FlipperNudge(Flipper1, Endangle1, EOSNudge1, Flipper2, EndAngle2)
	Dim b, BOT
	BOT = GetBalls

	If Flipper1.currentangle = Endangle1 and EOSNudge1 <> 1 Then
		EOSNudge1 = 1
		If Flipper2.currentangle = EndAngle2 Then 
			BOT = GetBalls
			For b = 0 to Ubound(BOT)
				If FlipperTrigger(BOT(b).x, BOT(b).y, Flipper1) Then
					exit Sub
				end If
			Next
			For b = 0 to Ubound(BOT)
				If FlipperTrigger(BOT(b).x, BOT(b).y, Flipper2) Then
					BOT(b).velx = BOT(b).velx / 1.3
					BOT(b).vely = BOT(b).vely - 0.5
				end If
			Next
		End If
	Else 
		If Abs(Flipper1.currentangle) > Abs(EndAngle1) + 30 then 
				EOSNudge1 = 0
		end if
	End If
End Sub

'*****************
' Maths
'*****************
Dim PI: PI = 4*Atn(1)

Function dSin(degrees)
	dsin = sin(degrees * Pi/180)
End Function

Function dCos(degrees)
	dcos = cos(degrees * Pi/180)
End Function

Function Atn2(dy, dx)
	If dx > 0 Then
		Atn2 = Atn(dy / dx)
	ElseIf dx < 0 Then
		If dy = 0 Then 
			Atn2 = pi
		Else
			Atn2 = Sgn(dy) * (pi - Atn(Abs(dy / dx)))
		end if
	ElseIf dx = 0 Then
		if dy = 0 Then
			Atn2 = 0
		else
			Atn2 = Sgn(dy) * pi / 2
		end if
	End If
End Function

'*************************************************
'  Check ball distance from Flipper for Rem
'*************************************************

Function Distance(ax,ay,bx,by)
	Distance = SQR((ax - bx)^2 + (ay - by)^2)
End Function

Function DistancePL(px,py,ax,ay,bx,by) ' Distance between a point and a line where point is px,py
	DistancePL = ABS((by - ay)*px - (bx - ax) * py + bx*ay - by*ax)/Distance(ax,ay,bx,by)
End Function

Function Radians(Degrees)
	Radians = Degrees * PI /180
End Function

Function AnglePP(ax,ay,bx,by)
	AnglePP = Atn2((by - ay),(bx - ax))*180/PI
End Function

Function DistanceFromFlipper(ballx, bally, Flipper)
	DistanceFromFlipper = DistancePL(ballx, bally, Flipper.x, Flipper.y, Cos(Radians(Flipper.currentangle+90))+Flipper.x, Sin(Radians(Flipper.currentangle+90))+Flipper.y)
End Function

Function FlipperTrigger(ballx, bally, Flipper)
	Dim DiffAngle
	DiffAngle  = ABS(Flipper.currentangle - AnglePP(Flipper.x, Flipper.y, ballx, bally) - 90)
	If DiffAngle > 180 Then DiffAngle = DiffAngle - 360

	If DistanceFromFlipper(ballx,bally,Flipper) < 48 and DiffAngle <= 90 and Distance(ballx,bally,Flipper.x,Flipper.y) < Flipper.Length Then
		FlipperTrigger = True
	Else
		FlipperTrigger = False
	End If        
End Function

'*************************************************
'  End - Check ball distance from Flipper for Rem
'*************************************************

dim LFPress, RFPress, LFCount, RFCount
dim LFState, RFState
dim EOST, EOSA,Frampup, FElasticity,FReturn
dim RFEndAngle, LFEndAngle

EOST = leftflipper.eostorque
EOSA = leftflipper.eostorqueangle
Frampup = LeftFlipper.rampup
FElasticity = LeftFlipper.elasticity
FReturn = LeftFlipper.return

Const EOSTnew = 1.1 
Const EOSAnew = 1
Const EOSRampup = 0

Dim SOSRampup:SOSRampup = 2.5

Const LiveCatch = 12
Const LiveElasticity = 0.45
Const SOSEM = 0.815
Const EOSReturn = 0.045

LFEndAngle = Leftflipper.endangle
RFEndAngle = RightFlipper.endangle

Sub FlipperActivate(Flipper, FlipperPress)
	FlipperPress = 1
	Flipper.Elasticity = FElasticity

	Flipper.eostorque = EOST         
	Flipper.eostorqueangle = EOSA         
End Sub

Sub FlipperDeactivate(Flipper, FlipperPress)
	FlipperPress = 0
	Flipper.eostorqueangle = EOSA
	Flipper.eostorque = EOST*EOSReturn/FReturn


	If Abs(Flipper.currentangle) <= Abs(Flipper.endangle) + 0.1 Then
		Dim b, BOT
		BOT = GetBalls

		For b = 0 to UBound(BOT)
			If Distance(BOT(b).x, BOT(b).y, Flipper.x, Flipper.y) < 55 Then 'check for cradle
				If BOT(b).vely >= -0.4 Then BOT(b).vely = -0.4
			End If
		Next
	End If
End Sub

Sub FlipperTricks (Flipper, FlipperPress, FCount, FEndAngle, FState) 
	Dim Dir
	Dir = Flipper.startangle/Abs(Flipper.startangle)        '-1 for Right Flipper

	If Abs(Flipper.currentangle) > Abs(Flipper.startangle) - 0.05 Then
		If FState <> 1 Then
			Flipper.rampup = SOSRampup 
			Flipper.endangle = FEndAngle - 3*Dir
			Flipper.Elasticity = FElasticity * SOSEM
			FCount = 0 
			FState = 1
		End If
	ElseIf Abs(Flipper.currentangle) <= Abs(Flipper.endangle) and FlipperPress = 1 then
		if FCount = 0 Then FCount = GameTime

		If FState <> 2 Then
			Flipper.eostorqueangle = EOSAnew
			Flipper.eostorque = EOSTnew
			Flipper.rampup = EOSRampup                        
			Flipper.endangle = FEndAngle
			FState = 2
		End If
	Elseif Abs(Flipper.currentangle) > Abs(Flipper.endangle) + 0.01 and FlipperPress = 1 Then 
		If FState <> 3 Then
			Flipper.eostorque = EOST        
			Flipper.eostorqueangle = EOSA
			Flipper.rampup = Frampup
			Flipper.Elasticity = FElasticity
			FState = 3
		End If

	End If
End Sub

Const LiveDistanceMin = 30  'minimum distance in vp units from flipper base live catch dampening will occur
Const LiveDistanceMax = 114  'maximum distance in vp units from flipper base live catch dampening will occur (tip protection)

Sub CheckLiveCatch(ball, Flipper, FCount, parm) 'Experimental new live catch
    Dim Dir
    Dir = Flipper.startangle/Abs(Flipper.startangle)    '-1 for Right Flipper
    Dim LiveCatchBounce                                                                                                                        'If live catch is not perfect, it won't freeze ball totally
    Dim CatchTime : CatchTime = GameTime - FCount

    if CatchTime <= LiveCatch and parm > 6 and ABS(Flipper.x - ball.x) > LiveDistanceMin and ABS(Flipper.x - ball.x) < LiveDistanceMax Then
            if CatchTime <= LiveCatch*0.5 Then                                                'Perfect catch only when catch time happens in the beginning of the window
                    LiveCatchBounce = 0
            else
                    LiveCatchBounce = Abs((LiveCatch/2) - CatchTime)        'Partial catch when catch happens a bit late
            end If

            If LiveCatchBounce = 0 and ball.velx * Dir > 0 Then ball.velx = 0
            ball.vely = LiveCatchBounce * (32 / LiveCatch) ' Multiplier for inaccuracy bounce
            ball.angmomx= 0
            ball.angmomy= 0
            ball.angmomz= 0
    Else
        If Abs(Flipper.currentangle) <= Abs(Flipper.endangle) + 1 Then FlippersD.Dampenf Activeball, parm, Rubberizer
    End If
End Sub

'******************************************************
' 				FLIPPER COLLIDE
'******************************************************

Sub LeftFlipper_Collide(parm)
	CheckLiveCatch Activeball, LeftFlipper, LFCount, parm
	LeftFlipperCollide parm
End Sub

Sub RightFlipper_Collide(parm)
	CheckLiveCatch Activeball, RightFlipper, RFCount, parm
 	RightFlipperCollide parm
End Sub

'******************************************************
'		FLIPPER CORRECTION INITIALIZATION
'******************************************************

dim LF : Set LF = New FlipperPolarity
dim RF : Set RF = New FlipperPolarity

InitPolarity

Sub InitPolarity()
	dim x, a : a = Array(LF, RF)
	for each x in a
		x.AddPoint "Ycoef", 0, RightFlipper.Y-65, 1        'disabled
		x.AddPoint "Ycoef", 1, RightFlipper.Y-11, 1
		x.enabled = True
		x.TimeDelay = 80
	Next


'	AddPt "Polarity", 0, 0, 0
'	AddPt "Polarity", 1, 0.05, -2.7        
'	AddPt "Polarity", 2, 0.33, -2.7
'	AddPt "Polarity", 3, 0.37, -2.7        
'	AddPt "Polarity", 4, 0.41, -2.7
'	AddPt "Polarity", 5, 0.45, -2.7
'	AddPt "Polarity", 6, 0.576,-2.7
'	AddPt "Polarity", 7, 0.66, -1.8
'	AddPt "Polarity", 8, 0.743, -0.5
'	AddPt "Polarity", 9, 0.81, -0.5
'	AddPt "Polarity", 10, 0.88, 0

	AddPt "Polarity", 0, 0, 0
	AddPt "Polarity", 1, 0.05, -3.7        
	AddPt "Polarity", 2, 0.33, -3.7
	AddPt "Polarity", 3, 0.37, -3.7
	AddPt "Polarity", 4, 0.41, -3.7
	AddPt "Polarity", 5, 0.45, -3.7 
	AddPt "Polarity", 6, 0.576,-3.7
	AddPt "Polarity", 7, 0.66, -2.3
	AddPt "Polarity", 8, 0.743, -1.5
	AddPt "Polarity", 9, 0.81, -1
	AddPt "Polarity", 10, 0.88, 0

	addpt "Velocity", 0, 0,         1
	addpt "Velocity", 1, 0.16, 1.06
	addpt "Velocity", 2, 0.41,         1.05
	addpt "Velocity", 3, 0.53,         1'0.982
	addpt "Velocity", 4, 0.702, 0.968
	addpt "Velocity", 5, 0.95,  0.968
	addpt "Velocity", 6, 1.03,         0.945

	LF.Object = LeftFlipper        
	LF.EndPoint = EndPointLp
	RF.Object = RightFlipper
	RF.EndPoint = EndPointRp
End Sub

Sub TriggerLF_Hit() : LF.Addball activeball : End Sub
Sub TriggerLF_UnHit() : LF.PolarityCorrect activeball : End Sub
Sub TriggerRF_Hit() : RF.Addball activeball : End Sub
Sub TriggerRF_UnHit() : RF.PolarityCorrect activeball : End Sub

'******************************************************
'  FLIPPER CORRECTION FUNCTIONS
'******************************************************

Sub AddPt(aStr, idx, aX, aY)	'debugger wrapper for adjusting flipper script in-game
	dim a : a = Array(LF, RF)
	dim x : for each x in a
		x.addpoint aStr, idx, aX, aY
	Next
End Sub

Class FlipperPolarity
	Public DebugOn, Enabled
	Private FlipAt        'Timer variable (IE 'flip at 723,530ms...)
	Public TimeDelay        'delay before trigger turns off and polarity is disabled TODO set time!
	private Flipper, FlipperStart,FlipperEnd, FlipperEndY, LR, PartialFlipCoef
	Private Balls(20), balldata(20)

	dim PolarityIn, PolarityOut
	dim VelocityIn, VelocityOut
	dim YcoefIn, YcoefOut
	Public Sub Class_Initialize 
		redim PolarityIn(0) : redim PolarityOut(0) : redim VelocityIn(0) : redim VelocityOut(0) : redim YcoefIn(0) : redim YcoefOut(0)
		Enabled = True : TimeDelay = 50 : LR = 1:  dim x : for x = 0 to uBound(balls) : balls(x) = Empty : set Balldata(x) = new SpoofBall : next 
	End Sub

	Public Property let Object(aInput) : Set Flipper = aInput : StartPoint = Flipper.x : End Property
	Public Property Let StartPoint(aInput) : if IsObject(aInput) then FlipperStart = aInput.x else FlipperStart = aInput : end if : End Property
	Public Property Get StartPoint : StartPoint = FlipperStart : End Property
	Public Property Let EndPoint(aInput) : FlipperEnd = aInput.x: FlipperEndY = aInput.y: End Property
	Public Property Get EndPoint : EndPoint = FlipperEnd : End Property        
	Public Property Get EndPointY: EndPointY = FlipperEndY : End Property

	Public Sub AddPoint(aChooseArray, aIDX, aX, aY) 'Index #, X position, (in) y Position (out) 
		Select Case aChooseArray
			case "Polarity" : ShuffleArrays PolarityIn, PolarityOut, 1 : PolarityIn(aIDX) = aX : PolarityOut(aIDX) = aY : ShuffleArrays PolarityIn, PolarityOut, 0
			Case "Velocity" : ShuffleArrays VelocityIn, VelocityOut, 1 :VelocityIn(aIDX) = aX : VelocityOut(aIDX) = aY : ShuffleArrays VelocityIn, VelocityOut, 0
			Case "Ycoef" : ShuffleArrays YcoefIn, YcoefOut, 1 :YcoefIn(aIDX) = aX : YcoefOut(aIDX) = aY : ShuffleArrays YcoefIn, YcoefOut, 0
		End Select
		if gametime > 100 then Report aChooseArray
	End Sub 

	Public Sub Report(aChooseArray)         'debug, reports all coords in tbPL.text
		if not DebugOn then exit sub
		dim a1, a2 : Select Case aChooseArray
			case "Polarity" : a1 = PolarityIn : a2 = PolarityOut
			Case "Velocity" : a1 = VelocityIn : a2 = VelocityOut
			Case "Ycoef" : a1 = YcoefIn : a2 = YcoefOut 
				case else :tbpl.text = "wrong string" : exit sub
		End Select
		dim str, x : for x = 0 to uBound(a1) : str = str & aChooseArray & " x: " & round(a1(x),4) & ", " & round(a2(x),4) & vbnewline : next
		tbpl.text = str
	End Sub

	Public Sub AddBall(aBall) : dim x : for x = 0 to uBound(balls) : if IsEmpty(balls(x)) then set balls(x) = aBall : exit sub :end if : Next  : End Sub

	Private Sub RemoveBall(aBall)
		dim x : for x = 0 to uBound(balls)
			if TypeName(balls(x) ) = "IBall" then 
				if aBall.ID = Balls(x).ID Then
					balls(x) = Empty
					Balldata(x).Reset
				End If
			End If
		Next
	End Sub

	Public Sub Fire() 
		Flipper.RotateToEnd
		processballs
	End Sub

	Public Property Get Pos 'returns % position a ball. For debug stuff.
		dim x : for x = 0 to uBound(balls)
			if not IsEmpty(balls(x) ) then
				pos = pSlope(Balls(x).x, FlipperStart, 0, FlipperEnd, 1)
			End If
		Next                
	End Property

	Public Sub ProcessBalls() 'save data of balls in flipper range
		FlipAt = GameTime
		dim x : for x = 0 to uBound(balls)
			if not IsEmpty(balls(x) ) then
				balldata(x).Data = balls(x)
			End If
		Next
		PartialFlipCoef = ((Flipper.StartAngle - Flipper.CurrentAngle) / (Flipper.StartAngle - Flipper.EndAngle))
		PartialFlipCoef = abs(PartialFlipCoef-1)
	End Sub
	Private Function FlipperOn() : if gameTime < FlipAt+TimeDelay then FlipperOn = True : End If : End Function        'Timer shutoff for polaritycorrect

	Public Sub PolarityCorrect(aBall)
		if FlipperOn() then 
			dim tmp, BallPos, x, IDX, Ycoef : Ycoef = 1

			'y safety Exit
			if aBall.VelY > -8 then 'ball going down
				RemoveBall aBall
				exit Sub
			end if

			'Find balldata. BallPos = % on Flipper
			for x = 0 to uBound(Balls)
				if aBall.id = BallData(x).id AND not isempty(BallData(x).id) then 
					idx = x
					BallPos = PSlope(BallData(x).x, FlipperStart, 0, FlipperEnd, 1)
					if ballpos > 0.65 then  Ycoef = LinearEnvelope(BallData(x).Y, YcoefIn, YcoefOut)                                'find safety coefficient 'ycoef' data
				end if
			Next

			If BallPos = 0 Then 'no ball data meaning the ball is entering and exiting pretty close to the same position, use current values.
				BallPos = PSlope(aBall.x, FlipperStart, 0, FlipperEnd, 1)
				if ballpos > 0.65 then  Ycoef = LinearEnvelope(aBall.Y, YcoefIn, YcoefOut)                                                'find safety coefficient 'ycoef' data
			End If

			'Velocity correction
			if not IsEmpty(VelocityIn(0) ) then
				Dim VelCoef
				VelCoef = LinearEnvelope(BallPos, VelocityIn, VelocityOut)

				if partialflipcoef < 1 then VelCoef = PSlope(partialflipcoef, 0, 1, 1, VelCoef)

				if Enabled then aBall.Velx = aBall.Velx*VelCoef
				if Enabled then aBall.Vely = aBall.Vely*VelCoef
			End If

			'Polarity Correction (optional now)
			if not IsEmpty(PolarityIn(0) ) then
				If StartPoint > EndPoint then LR = -1        'Reverse polarity if left flipper
				dim AddX : AddX = LinearEnvelope(BallPos, PolarityIn, PolarityOut) * LR
				'playsound "Knocker_1"
				if Enabled then aBall.VelX = aBall.VelX + 1 * (AddX*ycoef*PartialFlipcoef)
			End If
		End If
		RemoveBall aBall
	End Sub
End Class

'******************************************************
'  FLIPPER POLARITY AND RUBBER DAMPENER SUPPORTING FUNCTIONS 
'******************************************************

' Used for flipper correction and rubber dampeners
Sub ShuffleArray(ByRef aArray, byVal offset) 'shuffle 1d array
	dim x, aCount : aCount = 0
	redim a(uBound(aArray) )
	for x = 0 to uBound(aArray)        'Shuffle objects in a temp array
		if not IsEmpty(aArray(x) ) Then
			if IsObject(aArray(x)) then 
				Set a(aCount) = aArray(x)
			Else
				a(aCount) = aArray(x)
			End If
			aCount = aCount + 1
		End If
	Next
	if offset < 0 then offset = 0
	redim aArray(aCount-1+offset)        'Resize original array
	for x = 0 to aCount-1                'set objects back into original array
		if IsObject(a(x)) then 
			Set aArray(x) = a(x)
		Else
			aArray(x) = a(x)
		End If
	Next
End Sub

' Used for flipper correction and rubber dampeners
Sub ShuffleArrays(aArray1, aArray2, offset)
	ShuffleArray aArray1, offset
	ShuffleArray aArray2, offset
End Sub

' Used for flipper correction, rubber dampeners, and drop targets
Function BallSpeed(ball) 'Calculates the ball speed
	BallSpeed = SQR(ball.VelX^2 + ball.VelY^2 + ball.VelZ^2)
End Function

' Used for flipper correction and rubber dampeners
Function PSlope(Input, X1, Y1, X2, Y2)        'Set up line via two points, no clamping. Input X, output Y
	dim x, y, b, m : x = input : m = (Y2 - Y1) / (X2 - X1) : b = Y2 - m*X2
	Y = M*x+b
	PSlope = Y
End Function

' Used for flipper correction
Class spoofball 
	Public X, Y, Z, VelX, VelY, VelZ, ID, Mass, Radius 
	Public Property Let Data(aBall)
		With aBall
			x = .x : y = .y : z = .z : velx = .velx : vely = .vely : velz = .velz
			id = .ID : mass = .mass : radius = .radius
		end with
	End Property
	Public Sub Reset()
		x = Empty : y = Empty : z = Empty  : velx = Empty : vely = Empty : velz = Empty 
		id = Empty : mass = Empty : radius = Empty
	End Sub
End Class

' Used for flipper correction and rubber dampeners
Function LinearEnvelope(xInput, xKeyFrame, yLvl)
	dim y 'Y output
	dim L 'Line
	dim ii : for ii = 1 to uBound(xKeyFrame)        'find active line
		if xInput <= xKeyFrame(ii) then L = ii : exit for : end if
	Next
	if xInput > xKeyFrame(uBound(xKeyFrame) ) then L = uBound(xKeyFrame)        'catch line overrun
	Y = pSlope(xInput, xKeyFrame(L-1), yLvl(L-1), xKeyFrame(L), yLvl(L) )

	if xInput <= xKeyFrame(lBound(xKeyFrame) ) then Y = yLvl(lBound(xKeyFrame) )         'Clamp lower
	if xInput >= xKeyFrame(uBound(xKeyFrame) ) then Y = yLvl(uBound(xKeyFrame) )        'Clamp upper

	LinearEnvelope = Y
End Function

'******************************************************
'****  PHYSICS DAMPENERS
'******************************************************
'
' These are data mined bounce curves, 
' dialed in with the in-game elasticity as much as possible to prevent angle / spin issues.
' Requires tracking ballspeed to calculate COR

Sub dPosts_Hit(idx) 
	RubbersD.dampen Activeball
	TargetBouncer Activeball, 1
End Sub

Sub dSleeves_Hit(idx) 
	SleevesD.Dampen Activeball
	TargetBouncer Activeball, 0.7
End Sub

dim RubbersD : Set RubbersD = new Dampener        'frubber
RubbersD.name = "Rubbers"
RubbersD.debugOn = False        'shows info in textbox "TBPout"
RubbersD.Print = False        'debug, reports in debugger (in vel, out cor)

RubbersD.addpoint 0, 0, 1.1        'point# (keep sequential), ballspeed, CoR (elasticity)
RubbersD.addpoint 1, 3.77, 0.97
RubbersD.addpoint 2, 5.76, 0.967        'dont take this as gospel. if you can data mine rubber elasticitiy, please help!
RubbersD.addpoint 3, 15.84, 0.874
RubbersD.addpoint 4, 56, 0.64        'there's clamping so interpolate up to 56 at least

dim SleevesD : Set SleevesD = new Dampener        'this is just rubber but cut down to 85%...
SleevesD.name = "Sleeves"
SleevesD.debugOn = False        'shows info in textbox "TBPout"
SleevesD.Print = False        'debug, reports in debugger (in vel, out cor)
SleevesD.CopyCoef RubbersD, 0.85

'######################### Add new FlippersD Profile
'#########################    Adjust these values to increase or lessen the elasticity

dim FlippersD : Set FlippersD = new Dampener
FlippersD.name = "Flippers"
FlippersD.debugOn = False
FlippersD.Print = False	
FlippersD.addpoint 0, 0, 1.1	
FlippersD.addpoint 1, 3.77, 0.99
FlippersD.addpoint 2, 6, 0.99

'######################### Add Dampenf to Dampener Class 
'#########################    Only applies dampener when abs(velx) < 2 and vely < 0 and vely > -3.75  

Class Dampener
	Public Print, debugOn 'tbpOut.text
	public name, Threshold 	'Minimum threshold. Useful for Flippers, which don't have a hit threshold.
	Public ModIn, ModOut
	Private Sub Class_Initialize : redim ModIn(0) : redim Modout(0): End Sub 

	Public Sub AddPoint(aIdx, aX, aY) 
		ShuffleArrays ModIn, ModOut, 1 : ModIn(aIDX) = aX : ModOut(aIDX) = aY : ShuffleArrays ModIn, ModOut, 0
		if gametime > 100 then Report
	End Sub

	public sub Dampen(aBall)
		if threshold then if BallSpeed(aBall) < threshold then exit sub end if end if
		dim RealCOR, DesiredCOR, str, coef
		DesiredCor = LinearEnvelope(cor.ballvel(aBall.id), ModIn, ModOut )
		RealCOR = BallSpeed(aBall) / cor.ballvel(aBall.id)
		coef = desiredcor / realcor 
		if debugOn then str = name & " in vel:" & round(cor.ballvel(aBall.id),2 ) & vbnewline & "desired cor: " & round(desiredcor,4) & vbnewline & _
		"actual cor: " & round(realCOR,4) & vbnewline & "ballspeed coef: " & round(coef, 3) & vbnewline 
		if Print then debug.print Round(cor.ballvel(aBall.id),2) & ", " & round(desiredcor,3)
		
		aBall.velx = aBall.velx * coef : aBall.vely = aBall.vely * coef
		if debugOn then TBPout.text = str
	End Sub

	public sub Dampenf(aBall, parm, ver)
		if ver = 2 Then
			If parm < 10 And parm > 2 And Abs(aball.angmomz) < 15 And aball.vely < 0 then
				aball.angmomz = aball.angmomz * 1.2
				aball.vely = aball.vely * (1.1 + (parm/50))
			Elseif parm <= 2 and parm > 0.2 And aball.vely < 0 Then
				if (aball.velx > 0 And aball.angmomz > 0) Or (aball.velx < 0 And aball.angmomz < 0) then
			        	aball.angmomz = aball.angmomz * -0.7
				Else
					aball.angmomz = aball.angmomz * 1.2
				end if
				aball.vely = aball.vely * (1.2 + (parm/10))
			End if
		Else
			dim RealCOR, DesiredCOR, str, coef
			DesiredCor = LinearEnvelope(cor.ballvel(aBall.id), ModIn, ModOut )
			RealCOR = BallSpeed(aBall) / cor.ballvel(aBall.id)
			coef = desiredcor / realcor 
			If abs(aball.velx) < 2 and aball.vely < 0 and aball.vely > -3.75 then 
				aBall.velx = aBall.velx * coef : aBall.vely = aBall.vely * coef
			End If
		End If
	End Sub

	Public Sub CopyCoef(aObj, aCoef) 'alternative addpoints, copy with coef
		dim x : for x = 0 to uBound(aObj.ModIn)
			addpoint x, aObj.ModIn(x), aObj.ModOut(x)*aCoef
		Next
	End Sub

	Public Sub Report() 	'debug, reports all coords in tbPL.text
		if not debugOn then exit sub
		dim a1, a2 : a1 = ModIn : a2 = ModOut
		dim str, x : for x = 0 to uBound(a1) : str = str & x & ": " & round(a1(x),4) & ", " & round(a2(x),4) & vbnewline : next
		TBPout.text = str
	End Sub
End Class


'******************************************************
'  TRACK ALL BALL VELOCITIES
'  FOR RUBBER DAMPENER AND DROP TARGETS
'******************************************************

dim cor : set cor = New CoRTracker

Class CoRTracker
    public ballvel, ballvelx, ballvely, ballvelz, ballangmomx, ballangmomy, ballangmomz

    Private Sub Class_Initialize : redim ballvel(0) : redim ballvelx(0): redim ballvely(0) : redim ballvelz(0) : redim ballangmomx(0) : redim ballangmomy(0): redim ballangmomz(0): End Sub 

    Public Sub Update()    'tracks in-ball-velocity
        dim str, b, AllBalls, highestID : allBalls = getballs

        for each b in allballs
            if b.id >= HighestID then highestID = b.id
        Next

        if uBound(ballvel) < highestID then redim ballvel(highestID)    'set bounds
        if uBound(ballvelx) < highestID then redim ballvelx(highestID)    'set bounds
        if uBound(ballvely) < highestID then redim ballvely(highestID)    'set bounds
        if uBound(ballvelz) < highestID then redim ballvelz(highestID)    'set bounds
        if uBound(ballangmomx) < highestID then redim ballangmomx(highestID)    'set bounds
        if uBound(ballangmomy) < highestID then redim ballangmomy(highestID)    'set bounds
        if uBound(ballangmomz) < highestID then redim ballangmomz(highestID)    'set bounds

        for each b in allballs
            ballvel(b.id) = BallSpeed(b)
            ballvelx(b.id) = b.velx
            ballvely(b.id) = b.vely
            ballvelz(b.id) = b.velz
            ballangmomx(b.id) = b.angmomx
            ballangmomy(b.id) = b.angmomy
            ballangmomz(b.id) = b.angmomz
        Next
    End Sub
End Class

'******************************************************
'****  END PHYSICS DAMPENERS
'******************************************************

'******************************************************
' VPW TARGET BOUNCER (for targets and posts by Iaakki, Wrd1972, Apophis)
'******************************************************

sub TargetBouncer(aBall,defvalue)
    dim zMultiplier, vel, vratio
    if TargetBouncerEnabled = 1 and aball.z < 30 then
        vel = BallSpeed(aBall)
        if aBall.velx = 0 then vratio = 1 else vratio = aBall.vely/aBall.velx
        Select Case Int(Rnd * 6) + 1
            Case 1: zMultiplier = 0.2*defvalue
			Case 2: zMultiplier = 0.25*defvalue
            Case 3: zMultiplier = 0.3*defvalue
			Case 4: zMultiplier = 0.4*defvalue
            Case 5: zMultiplier = 0.45*defvalue
            Case 6: zMultiplier = 0.5*defvalue
        End Select
        aBall.velz = abs(vel * zMultiplier * TargetBouncerFactor)
        aBall.velx = sgn(aBall.velx) * sqr(abs((vel^2 - aBall.velz^2)/(1+vratio^2)))
        aBall.vely = aBall.velx * vratio
    elseif TargetBouncerEnabled = 2 and aball.z < 30 then
		'debug.print "velz: " & activeball.velz
		if aball.vely > 3 then	'only hard hits
			Select Case Int(Rnd * 4) + 1
				Case 1: zMultiplier = defvalue+1.1
				Case 2: zMultiplier = defvalue+1.05
				Case 3: zMultiplier = defvalue+0.7
				Case 4: zMultiplier = defvalue+0.3
			End Select
			aBall.velz = aBall.velz * zMultiplier * TargetBouncerFactor
		End If
	end if
end sub

Sub Target_Bounce_hit
	TargetBouncer Activeball, 1.1
End Sub

'******************************************************
'****  END TARGET BOUNCER
'******************************************************


'******************************************************
'	REAL-TIME UPDATES (Ball Rolling, Shadows, Etc)
'******************************************************

' ***** Physics, Animations, Shadows, and Sounds
Sub GameTimer_Timer()
	Cor.Update			'Dampener
	DoDTAnim			'Drop Target Animations
	DoSTAnim			'Stand Up Target Animations
	UpdateMechs			'Flipper, gates, and plunger updates
	SoundUpdates		'Rolling & Drop Sounds
End Sub


' ***** Lights Flashers and Scoring Display
Sub FrameTimer_Timer()
	LampTimer
	Lampztimer
	DisplayTimer
	BallShadowUpdates	'Ball Shadows	
End Sub


'*****************************************
'	MECHANICAL UPDATES
'*****************************************

sub UpdateMechs ()
	batleftshadow.rotz = LeftFlipper.CurrentAngle
	batrightshadow.rotz  = RightFlipper.CurrentAngle
	lflip.rotz = leftflipper.currentangle
	rflip.rotz = rightflipper.currentangle
	lflip001.rotz = leftflipper.currentangle
	rflip001.rotz = rightflipper.currentangle

	Diverter_prim.rotz = bottomgate.currentangle-55

	'*******************************************
	'  VR Plunger Code
	'*******************************************
	If plungerpress = 1 then
		If VR_Cab_plunger.Y < -166.5 then
			VR_Cab_plunger.Y = VR_Cab_plunger.Y + 3.1
		End If
	Else
		VR_Cab_plunger.Y = -321.5 + (7* Plunger.Position) - 25
	End If
End Sub

'******************************************************
'      		Rolling Sounds & Ball Shadows
'******************************************************

Const tnob = 4' total number of balls
ReDim rolling(tnob)
InitRolling

Dim DropCount
ReDim DropCount(tnob)

Dim ampFactor

Sub InitRolling
	Dim i
	For i = 0 to tnob
		rolling(i) = False
	Next
	Select Case BallRollAmpFactor
		Case 0
			ampFactor = "_amp0"
		Case 1
			ampFactor = "_amp2_5"
		Case 2
			ampFactor = "_amp5"
		Case 3
			ampFactor = "_amp7_5"
		Case 4
			ampFactor = "_amp9"
		Case Else
			ampFactor = "_amp0"
	End Select
End Sub

Sub SoundUpdates()
    Dim BOT, b

	b = -1
	' play the rolling sound for each ball
    For each BOT in Array(SSBall1, SSBall2, SSBall3)
		b = b + 1
        If BallVel(BOT) > 1 AND BOT.z < 30 Then
            rolling(b) = True
            PlaySound ("BallRoll_" & b & ampFactor), -1, VolPlayfieldRoll(BOT) * 1.1 * VolumeDial, AudioPan(BOT), 0, PitchPlayfieldRoll(BOT), 1, 0, AudioFade(BOT)
        Else
            If rolling(b) = True Then
                StopSound("BallRoll_" & b & ampFactor)
                rolling(b) = False
            End If
        End If

		'***Ball Drop Sounds***
		If BOT.VelZ < -1 and BOT.z < 55 and BOT.z > 27 Then 'height adjust for ball drop sounds
			If DropCount(b) >= 5 Then
				'DropCount(b) = 0
				If BOT.velz > -5 Then
					If BOT.z < 35 Then
						DropCount(b) = 0
						RandomSoundBallBouncePlayfieldSoft BOT
					End If
				Else
					DropCount(b) = 0
					RandomSoundBallBouncePlayfieldHard BOT
				End If				
			End If
		End If
		If DropCount(b) < 5 Then
			DropCount(b) = DropCount(b) + 1
		End If
    Next

End Sub


Dim BallShadow
BallShadow = Array (BallShadow1, BallShadow2, BallShadow3, BallShadow4, BallShadow5)

Sub BallShadowUpdates()
    Dim BOT, b

	b = -1

    For each BOT in Array(SSBall1, SSBall2, SSBall3)
		b = b + 1

		' "Static" Ball Shadows
		If AmbientBallShadowOn = 0 Then
			If BOT.Z > 30 Then
				BallShadowA(b).height = BOT.z - BallSize/4		'This is technically 1/4 of the ball "above" the ramp, but it keeps it from clipping
			Else
				BallShadowA(b).height = BOT.z - BallSize/2 + 5
			End If
			BallShadowA(b).Y = BOT.Y + Ballsize/5 + fovY
			BallShadowA(b).X = BOT.X
			BallShadowA(b).visible = 1

		' *** Normal "ambient light" ball shadow
		'Layered from top to bottom. If you had an upper pf at for example 80 and ramps even above that, your segments would be z>110; z<=110 And z>100; z<=100 And z>30; z<=30 And z>20; Else invisible

		ElseIf AmbientBallShadowOn = 1 Then			'Primitive shadow on playfield, flasher shadow in ramps
			If BOT.Z > 30 Then							'The flasher follows the ball up ramps while the primitive is on the pf
				If BOT.X < tablewidth/2 Then
					objBallShadow(b).X = ((BOT.X) - (Ballsize/10) + ((BOT.X - (tablewidth/2))/(Ballsize/AmbientMovement))) + 5
				Else
					objBallShadow(b).X = ((BOT.X) + (Ballsize/10) + ((BOT.X - (tablewidth/2))/(Ballsize/AmbientMovement))) - 5
				End If
				objBallShadow(b).Y = BOT.Y + BallSize/10 + fovY
				objBallShadow(b).visible = 1

				BallShadowA(b).X = BOT.X
				BallShadowA(b).Y = BOT.Y + BallSize/5 + fovY
				BallShadowA(b).height = BOT.z - BallSize/4		'This is technically 1/4 of the ball "above" the ramp, but it keeps it from clipping
				BallShadowA(b).visible = 1
			Elseif BOT.Z <= 30 And BOT.Z > 10 Then	'On pf, primitive only
				objBallShadow(b).visible = 1
				If BOT.X < tablewidth/2 Then
					objBallShadow(b).X = ((BOT.X) - (Ballsize/10) + ((BOT.X - (tablewidth/2))/(Ballsize/AmbientMovement))) + 5
				Else
					objBallShadow(b).X = ((BOT.X) + (Ballsize/10) + ((BOT.X - (tablewidth/2))/(Ballsize/AmbientMovement))) - 5
				End If
				objBallShadow(b).Y = BOT.Y + fovY
				BallShadowA(b).visible = 0
			Else											'Under pf, no shadows
				objBallShadow(b).visible = 0
				BallShadowA(b).visible = 0
			end if

		Elseif AmbientBallShadowOn = 2 Then		'Flasher shadow everywhere
			If BOT.Z > 30 Then							'In a ramp
				BallShadowA(b).X = BOT.X
				BallShadowA(b).Y = BOT.Y + BallSize/5 + fovY
				BallShadowA(b).height = BOT.z - BallSize/4		'This is technically 1/4 of the ball "above" the ramp, but it keeps it from clipping
				BallShadowA(b).visible = 1
			Elseif BOT.Z <= 30 And BOT.Z > 10 Then	'On pf
				BallShadowA(b).visible = 1
				If BOT.X < tablewidth/2 Then
					BallShadowA(b).X = ((BOT.X) - (Ballsize/10) + ((BOT.X - (tablewidth/2))/(Ballsize/AmbientMovement))) + 5
				Else
					BallShadowA(b).X = ((BOT.X) + (Ballsize/10) + ((BOT.X - (tablewidth/2))/(Ballsize/AmbientMovement))) - 5
				End If
				BallShadowA(b).Y = BOT.Y + Ballsize/10 + fovY
				BallShadowA(b).height = BOT.z - BallSize/2 + 5
			Else											'Under pf
				BallShadowA(b).visible = 0
			End If
		End If
	Next
	If DynamicBallShadowsOn Then DynamicBSUpdate
End Sub

'***************************************************************
'****  VPW DYNAMIC BALL SHADOWS by Iakki, Apophis, and Wylte
'***************************************************************

Const fovY					= 0		'Offset y position under ball to account for layback or inclination (more pronounced need further back)
Const DynamicBSFactor 		= 0.95	'0 to 1, higher is darker
Const AmbientBSFactor 		= 0.7	'0 to 1, higher is darker
Const AmbientMovement		= 2		'1 to 4, higher means more movement as the ball moves left and right
Const Wideness				= 20	'Sets how wide the dynamic ball shadows can get (20 +5 thinness should be most realistic for a 50 unit ball)
Const Thinness				= 5		'Sets minimum as ball moves away from source

' *** Required Functions

Function max(a,b)
	if a > b then 
		max = a
	Else
		max = b
	end if
end Function

Dim sourcenames, currentShadowCount, DSSources(30), numberofsources, numberofsources_hold

sourcenames = Array ("","","","","","","","","","","","")
currentShadowCount = Array (0,0,0,0,0,0,0,0,0,0,0,0)

' *** Trim or extend these to match the number of balls/primitives/flashers on the table!
dim objrtx1(12), objrtx2(12)
dim objBallShadow(12)
Dim BallShadowA
BallShadowA = Array (BallShadowA0,BallShadowA1,BallShadowA2,BallShadowA3,BallShadowA4,BallShadowA5,BallShadowA6,BallShadowA7,BallShadowA8,BallShadowA9,BallShadowA10,BallShadowA11)

DynamicBSInit

sub DynamicBSInit()
	Dim iii, Source

	for iii = 0 to tnob									'Prepares the shadow objects before play begins
		Set objrtx1(iii) = Eval("RtxBallShadow" & iii)
		objrtx1(iii).material = "RtxBallShadow" & iii
		objrtx1(iii).z = iii/1000 + 1.01
		objrtx1(iii).visible = 0

		Set objrtx2(iii) = Eval("RtxBall2Shadow" & iii)
		objrtx2(iii).material = "RtxBallShadow2_" & iii
		objrtx2(iii).z = (iii)/1000 + 1.02
		objrtx2(iii).visible = 0

		currentShadowCount(iii) = 0

		Set objBallShadow(iii) = Eval("BallShadow0" & iii)
		objBallShadow(iii).material = "BallShadow" & iii
		UpdateMaterial objBallShadow(iii).material,1,0,0,0,0,0,AmbientBSFactor,RGB(0,0,0),0,0,False,True,0,0,0,0
		objBallShadow(iii).Z = iii/1000 + 1.04
		objBallShadow(iii).visible = 0

		BallShadowA(iii).Opacity = 100*AmbientBSFactor
		BallShadowA(iii).visible = 0
	Next

	iii = 0

	For Each Source in DynamicSources
		DSSources(iii) = Array(Source.x, Source.y)
		iii = iii + 1
	Next
	numberofsources = iii
	numberofsources_hold = iii
end sub

Sub DynamicBSUpdate
	Dim falloff:	falloff = 150			'Max distance to light sources, can be changed if you have a reason
	Dim ShadowOpacity, ShadowOpacity2 
	Dim s, LSd, currentMat, AnotherSource, iii
	Dim BOT, Source
	
	s = -1
	For each BOT in Array(SSBall1, SSBall2, SSBall3)
		s = s + 1
		If BOT.Z < 30 and BOT.z > 20 and BOT.y < 1700 Then 'Defining when and where (on the table) you can have dynamic shadows
			For iii = 0 to numberofsources - 1 
				LSd=Distance(BOT.x, BOT.y, DSSources(iii)(0),DSSources(iii)(1))	'Calculating the Linear distance to the Source
				If LSd < falloff Then						    			'If the ball is within the falloff range of a light and light is on (we will set numberofsources to 0 when GI is off)
					currentShadowCount(s) = currentShadowCount(s) + 1		'Within range of 1 or 2
					if currentShadowCount(s) = 1 Then						'1 dynamic shadow source
						sourcenames(s) = iii 'ssource.name
						currentMat = objrtx1(s).material
						objrtx2(s).visible = 0 : objrtx1(s).visible = 1 : objrtx1(s).X = BOT.X : objrtx1(s).Y = BOT.Y + fovY
'						objrtx1(s).Z = BOT(s).Z - 25 + s/1000 + 0.01						'Uncomment if you want to add shadows to an upper/lower pf
						objrtx1(s).rotz = AnglePP(DSSources(iii)(0), DSSources(iii)(1), BOT.X, BOT.Y) + 90
						ShadowOpacity = (falloff-LSd)/falloff									'Sets opacity/darkness of shadow by distance to light
						objrtx1(s).size_y = Wideness*ShadowOpacity+Thinness						'Scales shape of shadow with distance/opacity
						UpdateMaterial currentMat,1,0,0,0,0,0,ShadowOpacity*DynamicBSFactor^2,RGB(0,0,0),0,0,False,True,0,0,0,0
						If AmbientBallShadowOn = 1 Then
							currentMat = objBallShadow(s).material									'Brightens the ambient primitive when it's close to a light
							UpdateMaterial currentMat,1,0,0,0,0,0,AmbientBSFactor*(1-ShadowOpacity),RGB(0,0,0),0,0,False,True,0,0,0,0
						Else
							BallShadowA(s).Opacity = 100*AmbientBSFactor*(1-ShadowOpacity)
						End If
					Elseif currentShadowCount(s) = 2 Then										'Same logic as 1 shadow, but twice
						currentMat = objrtx1(s).material
						AnotherSource = sourcenames(s)
						objrtx1(s).visible = 1 : objrtx1(s).X = BOT.X : objrtx1(s).Y = BOT.Y + fovY
'						objrtx1(s).Z = BOT(s).Z - 25 + s/1000 + 0.01							'Uncomment if you want to add shadows to an upper/lower pf
						objrtx1(s).rotz = AnglePP(DSSources(AnotherSource)(0),DSSources(AnotherSource)(1), BOT.X, BOT.Y) + 90
						ShadowOpacity = (falloff-Distance(BOT.x,BOT.y,DSSources(AnotherSource)(0),DSSources(AnotherSource)(1)))/falloff
						objrtx1(s).size_y = Wideness*ShadowOpacity+Thinness
						UpdateMaterial currentMat,1,0,0,0,0,0,ShadowOpacity*DynamicBSFactor^3,RGB(0,0,0),0,0,False,True,0,0,0,0

						currentMat = objrtx2(s).material
						objrtx2(s).visible = 1 : objrtx2(s).X = BOT.X : objrtx2(s).Y = BOT.Y + fovY
'						objrtx2(s).Z = BOT(s).Z - 25 + s/1000 + 0.02							'Uncomment if you want to add shadows to an upper/lower pf
						objrtx2(s).rotz = AnglePP(DSSources(iii)(0), DSSources(iii)(1), BOT.X, BOT.Y) + 90
						ShadowOpacity2 = (falloff-LSd)/falloff
						objrtx2(s).size_y = Wideness*ShadowOpacity2+Thinness
						UpdateMaterial currentMat,1,0,0,0,0,0,ShadowOpacity2*DynamicBSFactor^3,RGB(0,0,0),0,0,False,True,0,0,0,0
						If AmbientBallShadowOn = 1 Then
							currentMat = objBallShadow(s).material									'Brightens the ambient primitive when it's close to a light
							UpdateMaterial currentMat,1,0,0,0,0,0,AmbientBSFactor*(1-max(ShadowOpacity,ShadowOpacity2)),RGB(0,0,0),0,0,False,True,0,0,0,0
						Else
							BallShadowA(s).Opacity = 100*AmbientBSFactor*(1-max(ShadowOpacity,ShadowOpacity2))
						End If
					end if
				Else
					currentShadowCount(s) = 0
					BallShadowA(s).Opacity = 100*AmbientBSFactor
				End If
			Next
		Else									'Hide dynamic shadows everywhere else
			objrtx2(s).visible = 0 : objrtx1(s).visible = 0
		End If
	Next
End Sub


'******************************************************
'				Lights & Flashers
'******************************************************

Dim Sol9lvl
Dim Sol10lvl

fspace1.visible = false
fspace2.visible = false
fshuttle1.visible = false
fshuttle2.visible = false

sub Flash9(enabled)
	If enabled Then
		Sol9lvl = 1
		fspace1_timer
	else
		Sol9lvl = Sol9lvl * 0.7 'minor tweak to force faster fade
	End If
	Sound_Flash_Relay enabled, Relay_9
end sub


sub fspace1_timer
	if Not fspace1.TimerEnabled then				' This is here to detect the first call to this timer
		fspace1.visible = true
		fspace2.visible = true
		fspace1.TimerEnabled = true				' enabling this timer
	end if

	'debug.print Sol9lvl

	fspace1.opacity = 1250 * Sol9lvl^2
	fspace2.opacity = 1250 * Sol9lvl^2.5
	pHotDogSol9.blenddisablelighting = 120 * Sol9lvl^1

	Sol9lvl = 0.9 * Sol9lvl - 0.01			' Fading equation. 0.9 is rather slow. 0.6 is faster. Example 0.99 is too slow, but good for demo
	if Sol9lvl < 0 then Sol9lvl = 0			' failsafe so we are not going under 0

	if Sol9lvl =< 0 Then
		fspace1.visible = false
		fspace2.visible = false
		pHotDogSol9.blenddisablelighting = 0
		fspace1.TimerEnabled = false				' disabling this timer
	end if

end sub

sub Flash10(enabled)
	If enabled Then
		Sol10lvl = 1
		fshuttle1_timer
	else
		Sol10lvl = Sol10lvl * 0.7 'minor tweak to force faster fade
	End If
	Sound_Flash_Relay enabled, Relay_10
end sub


sub fshuttle1_timer
	if Not fshuttle1.TimerEnabled then				' This is here to detect the first call to this timer
		fshuttle1.visible = true
		fshuttle2.visible = true
		fshuttle1.TimerEnabled = true				' enabling this timer
	end if

	'debug.print Sol10lvl

	fshuttle1.opacity = 1250 * Sol10lvl^2
	fshuttle2.opacity = 1250 * Sol10lvl^2.5
	pHotDogSol10.blenddisablelighting = 120 * Sol10lvl^1

	Sol10lvl = 0.9 * Sol10lvl - 0.01			' Fading equation. 0.9 is rather slow. 0.6 is faster. Example 0.99 is too slow, but good for demo
	if Sol10lvl < 0 then Sol10lvl = 0			' failsafe so we are not going under 0

	if Sol10lvl =< 0 Then
		fshuttle1.visible = false
		fshuttle2.visible = false
		pHotDogSol10.blenddisablelighting = 0
		fshuttle1.TimerEnabled = false				' disabling this timer
	end if

end sub


dim GiIsOff

'Playfield GI
Sub PFGI(Enabled)
	If Enabled Then  ' GI state inverted, enabled = OFF
		dim xx
		For each xx in UV1col:xx.image="UV1off": Next
		For each xx in Bumperskirtcol:xx.image="uvbumpersoff": Next
		sw37.image="spin1off"
		SetLamp 111, 0
        GIIsOff=true
	Else
		For each xx in Bumperskirtcol:xx.image="UVbumpers": Next
		For each xx in UV1col:xx.image="UV1": Next
		sw37.image="spin1"
		SetLamp 111, 5
        GIIsOff=false
	End If
	' Update lamps that may swap textures when GI changes here
'	SetLamp 110, Not Enabled
'	SetLamp 111, Enabled
'	UpdateLamp25
'	UpdateLamp26
'	UpdateLamp27
	Sound_GI_Relay enabled, Relay_11
End Sub

'******************************************************
'****  LAMPZ
'******************************************************

Dim NullFader : set NullFader = new NullFadingObject
Dim Lampz : Set Lampz = New LampFader
Dim ModLampz : Set ModLampz = New DynamicLamps
InitLampsNF              ' Setup lamp assignments

Sub LampTimer()
	dim x, chglamp
	chglamp = Controller.ChangedLamps
	If Not IsEmpty(chglamp) Then
		For x = 0 To UBound(chglamp) 			'nmbr = chglamp(x, 0), state = chglamp(x, 1)
			Lampz.state(chglamp(x, 0)) = chglamp(x, 1)
		next
	End If
	Lampz.Update1	'update (fading logic only)
	ModLampz.Update1
'	Lampz.Update	'update (fading logic only)
'	ModLampz.Update
End Sub

dim FrameTime, InitFrameTime : InitFrameTime = 0
Sub Lampztimer()
	FrameTime = gametime - InitFrameTime : InitFrameTime = gametime	'Count frametime. Unused atm?
	Lampz.Update 'updates on frametime (Object updates only)
	ModLampz.Update

	If centerpost.blenddisablelighting > 0.1 Then
		CenterPost.image = "pp_popupON"
	Else
		CenterPost.image = "pp_popupOFF"
	End If

	If centerpost.transz = 25 Then
		lp1.state = 1 
		lp1.IntensityScale = lp2.IntensityScale
	else
		lp1.state = 0
	End If

End Sub

Function FlashLevelToIndex(Input, MaxSize)
	FlashLevelToIndex = cInt(MaxSize * Input)
End Function

'Material swap arrays.
'Dim TextureArray1: TextureArray1 = Array("Plastic with an image trans", "Plastic with an image trans","Plastic with an image trans","Plastic with an image")
Dim DLintensity

Sub DisableLighting(pri, DLintensity, ByVal aLvl)	'cp's script  DLintensity = disabled lighting intesity
	if Lampz.UseFunction then aLvl = Lampz.FilterOut(aLvl)	'Callbacks don't get this filter automatically
	pri.blenddisablelighting = aLvl * DLintensity
End Sub

sub DisableLightingMinMax(pri, DLintensityMin, DLintensityMax, ByVal aLvl)    'cp's script  DLintensity = disabled lighting intesity
    if Lampz.UseFunction then aLvl = Lampz.FilterOut(aLvl)    'Callbacks don't get this filter automatically
    pri.blenddisablelighting = (aLvl * (DLintensityMax-DLintensityMin)) + DLintensityMin
End Sub

Sub InitLampsNF()
	'Filtering (comment out to disable)
	Lampz.Filter = "LampFilter"	'Puts all lamp intensityscale output (no callbacks) through this function before updating
	ModLampz.Filter = "LampFilter"

	'Adjust fading speeds (1 / full MS fading time)
	dim x
	for x = 0 to 140 : Lampz.FadeSpeedUp(x) = 1/3 : Lampz.FadeSpeedDown(x) = 1/9 : next'1/20 : next
	for x = 0 to 28 : ModLampz.FadeSpeedUp(x) = 1/2 : ModLampz.FadeSpeedDown(x) = 1/30 : Next

	'for x = 0 to 140 : Lampz.FadeSpeedUp(x) = 1/80 : Lampz.FadeSpeedDown(x) = 1/100 : next
	Lampz.FadeSpeedUp(111) = 1/6 'GI
	Lampz.FadeSpeedDown(111) = 1/18

	'Lamp Assignments
	'MassAssign is an optional way to do assignments. It'll create arrays automatically / append objects to existing arrays

	Lampz.MassAssign(1)= BackglassGameOver
	Lampz.MassAssign(2)= BackglassMatch
	Lampz.MassAssign(3)= BackglassTilt
	Lampz.MassAssign(4)= BackglassHighScore
	Lampz.MassAssign(5)= BackglassShootAgain
	Lampz.MassAssign(6)= BackglassBIP

	Lampz.MassAssign(7)= CPFlash1
	Lampz.MassAssign(7)= CPFlash2
	Lampz.MassAssign(7)= lp2
	Lampz.Callback(7) = "DisableLighting centerpost, 0.15,"

	Lampz.MassAssign(8)= l8
	Lampz.MassAssign(8)= l8B
	Lampz.Callback(8) = "DisableLighting p8, 12,"
	Lampz.Callback(8) = "DisableLighting p8o, 22,"
	Lampz.MassAssign(9)= l9
	Lampz.MassAssign(9)= l9B
	Lampz.Callback(9) = "DisableLighting p9, 12,"
	Lampz.Callback(9) = "DisableLighting p9o, 22,"
	Lampz.MassAssign(10)= l10
	Lampz.MassAssign(10)= l10B
	Lampz.Callback(10) = "DisableLighting p10, 12,"
	Lampz.Callback(10) = "DisableLighting p10o, 22,"
	Lampz.MassAssign(11)= l11
	Lampz.MassAssign(11)= l11B
	Lampz.Callback(11) = "DisableLighting p11, 12,"
	Lampz.Callback(11) = "DisableLighting p11o, 22,"
	Lampz.MassAssign(12)= l12
	Lampz.MassAssign(12)= l12B
	Lampz.Callback(12) = "DisableLighting p12, 12,"
	Lampz.Callback(12) = "DisableLighting p12o, 22,"
	Lampz.MassAssign(13)= l13
	Lampz.MassAssign(13)= l13B
	Lampz.Callback(13) = "DisableLighting p13, 12,"
	Lampz.Callback(13) = "DisableLighting p13o, 22,"
	Lampz.MassAssign(14)= l14
	Lampz.MassAssign(14)= l14B
	Lampz.Callback(14) = "DisableLighting p14, 12,"
	Lampz.Callback(14) = "DisableLighting p14o, 22,"
	Lampz.MassAssign(15)= l15
	Lampz.MassAssign(15)= l15B
	Lampz.MassAssign(15)= l15C
	Lampz.MassAssign(15)= l15D
	Lampz.Callback(15) = "DisableLighting p15, 12,"
	Lampz.Callback(15) = "DisableLighting p15A, 12,"
	Lampz.Callback(15) = "DisableLighting p15o, 22,"
	Lampz.Callback(15) = "DisableLighting p15Ao, 22,"
	Lampz.MassAssign(16)= l16
	Lampz.MassAssign(16)= l16B
	Lampz.Callback(16) = "DisableLighting p16, 12,"
	Lampz.Callback(16) = "DisableLighting p16o, 12,"
	Lampz.MassAssign(17)= l17
	Lampz.MassAssign(17)= l17B
	Lampz.Callback(17) = "DisableLighting p17, 12,"
	Lampz.Callback(17) = "DisableLighting p17o, 22,"
	Lampz.MassAssign(18)= l18
	Lampz.MassAssign(18)= l18B
	Lampz.Callback(18) = "DisableLighting p18, 12,"
	Lampz.Callback(18) = "DisableLighting p18o, 22,"
	Lampz.MassAssign(19)= l19
	Lampz.MassAssign(19)= l19B
	Lampz.Callback(19) = "DisableLighting p19, 12,"
	Lampz.Callback(19) = "DisableLighting p19o, 22,"
	Lampz.MassAssign(20)= l20
	Lampz.MassAssign(20)= l20B
	Lampz.Callback(20) = "DisableLighting p20, 12,"
	Lampz.Callback(20) = "DisableLighting p20o, 22,"
	Lampz.MassAssign(21)= l21
	Lampz.MassAssign(21)= l21B
	Lampz.Callback(21) = "DisableLighting p21, 12,"
	Lampz.Callback(21) = "DisableLighting p21o, 22,"
	Lampz.MassAssign(22)= l22
	Lampz.MassAssign(22)= l22B
	Lampz.Callback(22) = "DisableLighting p22, 12,"
	Lampz.Callback(22) = "DisableLighting p22o, 22,"
	Lampz.MassAssign(23)= l23
	Lampz.MassAssign(23)= l23B
	Lampz.Callback(23) = "DisableLighting p23, 12,"
	Lampz.Callback(23) = "DisableLighting p23o, 22,"
	Lampz.MassAssign(24)= l24
	Lampz.MassAssign(24)= l24B
	Lampz.Callback(24) = "DisableLighting p24, 12,"
	Lampz.Callback(24) = "DisableLighting p24o, 12,"
	Lampz.MassAssign(25)= l25
	Lampz.MassAssign(25)= l25B
	Lampz.Callback(25) = "DisableLightingMinMax p25, 1, 1.8,"
	Lampz.Callback(27) = "DisableLightingMinMax p25off, 1, 2,"
	Lampz.Callback(25) = "DisableLightingMinMax bumperskirt001, 1, 1.01,"
	Lampz.MassAssign(26)= l26
	Lampz.MassAssign(26)= l26B
	Lampz.Callback(26) = "DisableLightingMinMax p26, 1, 1.8,"
	Lampz.Callback(27) = "DisableLightingMinMax p26off, 1, 2,"
	Lampz.Callback(26) = "DisableLightingMinMax bumperskirt002, 1, 1.01,"
	Lampz.MassAssign(27)= l27
	Lampz.MassAssign(27)= l27B
	Lampz.Callback(27) = "DisableLightingMinMax p27, 1, 1.8,"
	Lampz.Callback(27) = "DisableLightingMinMax p27off, 1, 2,"
	Lampz.Callback(27) = "DisableLightingMinMax bumperskirt003, 1, 1.01,"
	Lampz.MassAssign(28)= l28
	Lampz.MassAssign(28)= l28B
	Lampz.Callback(28) = "DisableLighting p28, 12,"
	Lampz.Callback(28) = "DisableLighting p28o, 12,"
	Lampz.MassAssign(29)= l29
	Lampz.MassAssign(29)= l29B
	Lampz.Callback(29) = "DisableLighting p29, 12,"
	Lampz.Callback(29) = "DisableLighting p29o, 22,"
	Lampz.MassAssign(30)= l30
	Lampz.MassAssign(30)= l30B
	Lampz.Callback(30) = "DisableLighting p30, 12,"
	Lampz.Callback(30) = "DisableLighting p30o, 22,"
	Lampz.MassAssign(31)= l31
	Lampz.MassAssign(31)= l31B
	Lampz.Callback(31) = "DisableLighting p31, 12,"
	Lampz.Callback(31) = "DisableLighting p31o, 22,"
	Lampz.MassAssign(32)= l32
	Lampz.MassAssign(32)= l32B
	Lampz.Callback(32) = "DisableLighting p32, 12,"
	Lampz.Callback(32) = "DisableLighting p32o, 22,"
	Lampz.MassAssign(33)= l33
	Lampz.MassAssign(33)= l33B
	Lampz.Callback(33) = "DisableLighting p33, 12,"
	Lampz.Callback(33) = "DisableLighting p33o, 12,"
	Lampz.MassAssign(34)= l34
	Lampz.MassAssign(34)= l34B
	Lampz.Callback(34) = "DisableLighting p34, 12,"
	Lampz.Callback(34) = "DisableLighting p34o, 12,"
	Lampz.MassAssign(35)= l35
	Lampz.MassAssign(35)= l35B
	Lampz.Callback(35) = "DisableLighting p35, 12,"
	Lampz.Callback(35) = "DisableLighting p35o, 12,"
	Lampz.MassAssign(36)= l36
	Lampz.MassAssign(36)= l36B
	Lampz.Callback(36) = "DisableLighting p36, 12,"
	Lampz.Callback(36) = "DisableLighting p36o, 12,"
	Lampz.MassAssign(37)= l37
	Lampz.MassAssign(37)= l37B
	Lampz.Callback(37) = "DisableLighting p37, 12,"
	Lampz.Callback(37) = "DisableLighting p37o, 22,"

	Lampz.MassAssign(38)= BackglassStopandScore
	Lampz.MassAssign(39)= BGFL39
	Lampz.MassAssign(39)= BGFL39a
	Lampz.MassAssign(40)= BGFL40

	Lampz.MassAssign(41)= l41
	Lampz.MassAssign(41)= l41B
	Lampz.MassAssign(41)= l41C
	Lampz.MassAssign(41)= l41D
	Lampz.MassAssign(42)= l42
	Lampz.MassAssign(42)= l42B
	Lampz.Callback(42) = "DisableLighting p42, 12,"
	Lampz.Callback(42) = "DisableLighting p42o, 22,"
	Lampz.MassAssign(43)= l43
	Lampz.MassAssign(43)= l43B
	Lampz.Callback(43) = "DisableLighting p43, 12,"
	Lampz.Callback(43) = "DisableLighting p43o, 22,"	
	Lampz.MassAssign(44)= l44
	Lampz.MassAssign(44)= l44B
	Lampz.Callback(44) = "DisableLighting p44, 12,"
	Lampz.Callback(44) = "DisableLighting p44o, 22,"	
	Lampz.MassAssign(45)= l45
	Lampz.MassAssign(45)= l45B
	Lampz.Callback(45) = "DisableLighting p45, 12,"
	Lampz.Callback(45) = "DisableLighting p45o, 22,"
	Lampz.MassAssign(46)= l46
	Lampz.MassAssign(46)= l46B
	Lampz.MassAssign(47)= l47
	Lampz.MassAssign(47)= l47B
	Lampz.Callback(47) = "DisableLighting p47, 12,"
	Lampz.Callback(47) = "DisableLighting p47o, 22,"
	Lampz.MassAssign(48)= l48
	Lampz.MassAssign(48)= l48B
	Lampz.Callback(48) = "DisableLighting p48, 12,"
	Lampz.Callback(48) = "DisableLighting p48o, 22,"
	Lampz.MassAssign(49)= l49
	Lampz.MassAssign(49)= l49B
	Lampz.Callback(49) = "DisableLighting p49, 12,"
	Lampz.Callback(49) = "DisableLighting p49o, 12,"
	Lampz.MassAssign(50)= l50
	Lampz.MassAssign(51)= l51
	Lampz.MassAssign(52)= l52
	Lampz.MassAssign(53)= l53
	Lampz.MassAssign(54)= l54
	Lampz.MassAssign(55)= l55
	Lampz.MassAssign(56)= l56
	Lampz.MassAssign(57)= l57
	Lampz.MassAssign(58)= l58
	Lampz.MassAssign(59)= l59
	Lampz.MassAssign(60)= l60
	Lampz.MassAssign(61)= l61
	Lampz.MassAssign(62)= l62
	Lampz.MassAssign(63)= l63
	Lampz.MassAssign(64)= l64


'	'Sol 10 GI relay and assignments
'	Lampz.obj(111) = ColtoArray(GI)	
'
	For each x in GI:Lampz.MassAssign(111) = x:Next	
	Lampz.Callback(111) = "GIUpdates"
	Lampz.MassAssign(103) = BGFL40a 

'	Lampz.state(111) = 1		'Turn on GI to Start


	'Turn off all lamps on startup
	lampz.Init	'This just turns state of any lamps to 1
	ModLampz.Init

	'Immediate update to turn on GI, turn off lamps
	lampz.update
	ModLampz.Update

End Sub


'***************************************
'System 11 GI On/Off
'***************************************
Sub GIOn  : SetGI False: End Sub 'These are just debug commands now
Sub GIOff : SetGI True : End Sub


Dim GIoffMult : GIoffMult = 2 'adjust how bright the inserts get when the GI is off
Dim GIoffMultFlashers : GIoffMultFlashers = 2	'adjust how bright the Flashers get when the GI is off


'Dim TextureArray1: TextureArray1 = Array("Plastic with an image trans", "Plastic with an image trans","Plastic with an image trans","Plastic with an image")
dim gilvl
'const ballbrightMax = 105
'const ballbrightMin = 15

Dim GIX
Sub GIupdates(ByVal aLvl)	'GI update odds and ends go here
	if Lampz.UseFunction then aLvl = LampFilter(aLvl)	'Callbacks don't get this filter automatically

	'debug.print aLvl

	UpdateMaterial "meshtop",0,0,0,0,0,0,aLvl^3,RGB(247,247,247),0,0,False,True,0,0,0,0
	UpdateMaterial "meshtop1",0,0,0,0,0,0,aLvl,RGB(247,247,247),0,0,False,True,0,0,0,0
	UpdateMaterial "pfoff",0,0,0,0,0,0,1-aLvl,RGB(247,247,247),0,0,False,True,0,0,0,0

	If aLvl = 0 Then numberofsources = 0 else numberofsources = numberofsources_hold 'Dynamic Ball Shadows

'	if ObjLevel(1) <= 0 And ObjLevel(2) <= 0 Then
'		'commenting this out for now, as it has issues with flashers
'		if aLvl = 0 then										'GI OFF, let's hide ON prims
'			OnPrimsVisible False
'			for each GIX in GI:GIX.state = 0:Next
'			if ballbrightness <> -1 then ballbrightness = ballbrightMin
'		Elseif aLvl = 1 then									'GI ON, let's hide OFF prims
'			OffPrimsVisible False
'			for each GIX in GI:GIX.state = 1:Next
'			if ballbrightness <> -1 then ballbrightness = ballbrightMax
'		Else
'			if giprevalvl = 0 Then								'GI has just changed from OFF to fading, let's show ON
'				'fx_relay_on
'				OnPrimsVisible True
'				ballbrightness = ballbrightMin + 1
'			elseif giprevalvl = 1 Then							'GI has just changed from ON to fading, let's show OFF
'				'fx_relay_off
'				OffPrimsVisible true
'				ballbrightness = ballbrightMax - 1
'			Else
'				'no change
'			end if
'		end if
'
'		UpdateMaterial "GI_ON_CAB",		0,0,0,0,0,0,aLvl^2,RGB(255,255,255),0,0,False,True,0,0,0,0
'		UpdateMaterial "GI_ON_Plastic",	0,0,0,0,0,0,aLvl^3,RGB(255,255,255),0,0,False,True,0,0,0,0
'		UpdateMaterial "GI_ON_Metals",	0,0,0,0,0,0,aLvl^1,RGB(255,255,255),0,0,False,True,0,0,0,0
'		UpdateMaterial "GI_ON_Bulbs",	0,0,0,0,0,0,aLvl^1,RGB(255,255,255),0,0,False,True,0,0,0,0
'	Elseif ObjLevel(1) > 0 Or ObjLevel(2) > 0 then 
'		if aLvl = 0 Or aLvl = 1 then
'			'nothing, flashers just fading and no real change to gi
'		Elseif giprevalvl = 0 then 'gi went ON while some flasher was fading
'			'debug.print "##on prims to on image"
'			OnPrimSwap "ON"
'		elseif giprevalvl = 1 Then 'gi went OFF while some flasher was fading
'			'debug.print "##on prims to OFF images"
'			OnPrimSwap "OFF"
'		end if
'		
'	end If

'Sideblades: ^5 (fastest to go off)
'Plastics: ^3 (medium speed)
'Bulbs: ^0.5 (not sure how this would look. Would be the slowest)
'metals:^2
'
'GI_ON_Bulbs
'GI_ON_CAB
'GI_ON_Metals
'GI_ON_Plastic

	'debug.print aLvl
	'debug.print aLvl^5
'
'	PLAYFIELD_GI1.opacity = PFGIOFFOpacity - (PFGIOFFOpacity * alvl^3) 'TODO 60
'
'	'debug.print "*** --> " & FlashLevelToIndex(aLvl, 3)
'
'    Select case FlashLevelToIndex(aLvl, 3)
'		Case 0:plastics.Image = "plastics_000"
'		Case 1:plastics.Image = "plastics_033"
'		Case 2:plastics.Image = "plastics_066"
'        Case 3:plastics.Image = "plastics_100"
'    End Select
'	
'	'0.7 - 0.05
'	FlasherOffBrightness = 0.7*aLvl
'	Flasherbase2.blenddisablelighting = FlasherOffBrightness
'	Flasherbase1.blenddisablelighting = FlasherOffBrightness
'
'	lamp_bulbs.blenddisablelighting = 10 * aLvl : lamp_bulbsOFF.blenddisablelighting = 10 * aLvl
'	bulbs.blenddisablelighting = 0.5 * aLvl : bulbsOFF.blenddisablelighting = 0.5 * aLvl
'
'	'ball
'	if ballbrightness <> ballbrightMax Or ballbrightness <> ballbrightMin Or ballbrightness <> -1 then ballbrightness = INT(alvl * (ballbrightMax - ballbrightMin) + ballbrightMin)
'	

	gilvl = alvl

End Sub

'Lamp Filter
Function LampFilter(aLvl)

	LampFilter = aLvl^1.6	'exponential curve?
End Function



'Helper functions

Function ColtoArray(aDict)	'converts a collection to an indexed array. Indexes will come out random probably.
	redim a(999)
	dim count : count = 0
	dim x  : for each x in aDict : set a(Count) = x : count = count + 1 : Next
	redim preserve a(count-1) : ColtoArray = a
End Function

'Set GICallback2 = GetRef("SetGI")

'Sub SetGI(aNr, aValue)
'	msgbox "GI nro: " & aNr & " and step: " & aValue
'	ModLampz.SetGI aNr, aValue 'Redundant. Could reassign GI indexes here
'End Sub


'Dim GiOffFOP
'Sub SetGI(aOn)
''	PlayRelay aOn, 13
'	Select Case aOn
'		Case True  'GI off
'			'fx_relay_off
'			PlaySoundAtLevelStatic ("fx_relay_off"), RelaySoundLevel, p30off
'			SetLamp 111, 0	'Inverted, Solenoid cuts GI circuit on this era of game
'			l57.intensity=66:l58.intensity=66:l59.intensity=66
'			l57.falloff=250:l58.falloff=250:l59.falloff=250
'		Case False 
'			'fx_relay_on
'			PlaySoundAtLevelStatic ("fx_relay_on"), RelaySoundLevel, p30off
'			SetLamp 111, 5
'			l57.intensity=11:l58.intensity=11:l59.intensity=11
'			l57.falloff=200:l58.falloff=200:l59.falloff=200
'	End Select
'End Sub

Sub SetLamp(aNr, aOn)
'	if aNr = 111 then
'		msgbox gametime & " GI: " & aOn
'	end if
	Lampz.state(aNr) = abs(aOn)
End Sub

Sub SetModLamp(aNr, aInput)
	ModLampz.state(aNr) = abs(aInput)/255
End Sub

'****************************************************************
'				Class jungle nf (what does this mean?!?)
'****************************************************************

'No-op object instead of adding more conditionals to the main loop
'It also prevents errors if empty lamp numbers are called, and it's only one object
'should be g2g?

Class NullFadingObject : Public Property Let IntensityScale(input) : : End Property : End Class

'version 0.11 - Mass Assign, Changed modulate style
'version 0.12 - Update2 (single -1 timer update) update method for core.vbs
'Version 0.12a - Filter can now be accessed via 'FilterOut'
'Version 0.12b - Changed MassAssign from a sub to an indexed property (new syntax: lampfader.MassAssign(15) = Light1 )
'Version 0.13 - No longer requires setlocale. Callback() can be assigned multiple times per index
' Note: if using multiple 'LampFader' objects, set the 'name' variable to avoid conflicts with callbacks

Class LampFader
	Public FadeSpeedDown(140), FadeSpeedUp(140)
	Private Lock(140), Loaded(140), OnOff(140)
	Public UseFunction
	Private cFilter
	Public UseCallback(140), cCallback(140)
	Public Lvl(140), Obj(140)
	Private Mult(140)
	Public FrameTime
	Private InitFrame
	Public Name

	Sub Class_Initialize()
		InitFrame = 0
		dim x : for x = 0 to uBound(OnOff) 	'Set up fade speeds
			FadeSpeedDown(x) = 1/100	'fade speed down
			FadeSpeedUp(x) = 1/80		'Fade speed up
			UseFunction = False
			lvl(x) = 0
			OnOff(x) = False
			Lock(x) = True : Loaded(x) = False
			Mult(x) = 1
		Next
		Name = "LampFaderNF" 'NEEDS TO BE CHANGED IF THERE'S MULTIPLE OF THESE OBJECTS, OTHERWISE CALLBACKS WILL INTERFERE WITH EACH OTHER!!
		for x = 0 to uBound(OnOff) 		'clear out empty obj
			if IsEmpty(obj(x) ) then Set Obj(x) = NullFader' : Loaded(x) = True
		Next
	End Sub

	Public Property Get Locked(idx) : Locked = Lock(idx) : End Property		'debug.print Lampz.Locked(100)	'debug
	Public Property Get state(idx) : state = OnOff(idx) : end Property
	Public Property Let Filter(String) : Set cFilter = GetRef(String) : UseFunction = True : End Property
	Public Function FilterOut(aInput) : if UseFunction Then FilterOut = cFilter(aInput) Else FilterOut = aInput End If : End Function
	'Public Property Let Callback(idx, String) : cCallback(idx) = String : UseCallBack(idx) = True : End Property
	Public Property Let Callback(idx, String)
		UseCallBack(idx) = True
		'cCallback(idx) = String 'old execute method
		'New method: build wrapper subs using ExecuteGlobal, then call them
		cCallback(idx) = cCallback(idx) & "___" & String	'multiple strings dilineated by 3x _

		dim tmp : tmp = Split(cCallback(idx), "___")

		dim str, x : for x = 0 to uBound(tmp)	'build proc contents
			'If Not tmp(x)="" then str = str & "	" & tmp(x) & " aLVL" & "	'" & x & vbnewline	'more verbose
			If Not tmp(x)="" then str = str & tmp(x) & " aLVL:"
		Next

		dim out : out = "Sub " & name & idx & "(aLvl):" & str & "End Sub"
		'if idx = 132 then msgbox out	'debug
		ExecuteGlobal Out

	End Property

	Public Property Let state(ByVal idx, input) 'Major update path
		if Input <> OnOff(idx) then  'discard redundant updates
			OnOff(idx) = input
			Lock(idx) = False
			Loaded(idx) = False
		End If
	End Property

	'Mass assign, Builds arrays where necessary
	'Sub MassAssign(aIdx, aInput)
	Public Property Let MassAssign(aIdx, aInput)
		If typename(obj(aIdx)) = "NullFadingObject" Then 'if empty, use Set
			if IsArray(aInput) then
				obj(aIdx) = aInput
			Else
				Set obj(aIdx) = aInput
			end if
		Else
			Obj(aIdx) = AppendArray(obj(aIdx), aInput)
		end if
	end Property

	Sub SetLamp(aIdx, aOn) : state(aIdx) = aOn : End Sub	'Solenoid Handler

	Public Sub TurnOnStates()	'If obj contains any light objects, set their states to 1 (Fading is our job!)
		dim debugstr
		dim idx : for idx = 0 to uBound(obj)
			if IsArray(obj(idx)) then
				'debugstr = debugstr & "array found at " & idx & "..."
				dim x, tmp : tmp = obj(idx) 'set tmp to array in order to access it
				for x = 0 to uBound(tmp)
					if typename(tmp(x)) = "Light" then DisableState tmp(x)' : debugstr = debugstr & tmp(x).name & " state'd" & vbnewline
					tmp(x).intensityscale = 0.001 ' this can prevent init stuttering
				Next
			Else
				if typename(obj(idx)) = "Light" then DisableState obj(idx)' : debugstr = debugstr & obj(idx).name & " state'd (not array)" & vbnewline
				obj(idx).intensityscale = 0.001 ' this can prevent init stuttering
			end if
		Next
		'debug.print debugstr
	End Sub
	Private Sub DisableState(ByRef aObj) : aObj.FadeSpeedUp = 0.2 : aObj.State = 1 : End Sub	'turn state to 1

	Public Sub Init()	'Just runs TurnOnStates right now
		TurnOnStates
	End Sub

	Public Property Let Modulate(aIdx, aCoef) : Mult(aIdx) = aCoef : Lock(aIdx) = False : Loaded(aIdx) = False: End Property
	Public Property Get Modulate(aIdx) : Modulate = Mult(aIdx) : End Property

	Public Sub Update1()	 'Handle all boolean numeric fading. If done fading, Lock(x) = True. Update on a '1' interval Timer!
		dim x : for x = 0 to uBound(OnOff)
			if not Lock(x) then 'and not Loaded(x) then
				if OnOff(x) then 'Fade Up
					Lvl(x) = Lvl(x) + FadeSpeedUp(x)
					if Lvl(x) >= 1 then Lvl(x) = 1 : Lock(x) = True
				elseif Not OnOff(x) then 'fade down
					Lvl(x) = Lvl(x) - FadeSpeedDown(x)
					if Lvl(x) <= 0 then Lvl(x) = 0 : Lock(x) = True
				end if
			end if
		Next
	End Sub

	Public Sub Update2()	 'Both updates on -1 timer (Lowest latency, but less accurate fading at 60fps vsync)
		FrameTime = gametime - InitFrame : InitFrame = GameTime	'Calculate frametime
		dim x : for x = 0 to uBound(OnOff)
			if not Lock(x) then 'and not Loaded(x) then
				if OnOff(x) then 'Fade Up
					Lvl(x) = Lvl(x) + FadeSpeedUp(x) * FrameTime
					if Lvl(x) >= 1 then Lvl(x) = 1 : Lock(x) = True
				elseif Not OnOff(x) then 'fade down
					Lvl(x) = Lvl(x) - FadeSpeedDown(x) * FrameTime
					if Lvl(x) <= 0 then Lvl(x) = 0 : Lock(x) = True
				end if
			end if
		Next
		Update
	End Sub

	Public Sub Update()	'Handle object updates. Update on a -1 Timer! If done fading, loaded(x) = True
		dim x,xx : for x = 0 to uBound(OnOff)
			if not Loaded(x) then
				if IsArray(obj(x) ) Then	'if array
					If UseFunction then
						for each xx in obj(x) : xx.IntensityScale = cFilter(Lvl(x)*Mult(x)) : Next
					Else
						for each xx in obj(x) : xx.IntensityScale = Lvl(x)*Mult(x) : Next
					End If
				else						'if single lamp or flasher
					If UseFunction then
						obj(x).Intensityscale = cFilter(Lvl(x)*Mult(x))
					Else
						obj(x).Intensityscale = Lvl(x)
					End If
				end if
				if TypeName(lvl(x)) <> "Double" and typename(lvl(x)) <> "Integer" then msgbox "uhh " & 2 & " = " & lvl(x)
				'If UseCallBack(x) then execute cCallback(x) & " " & (Lvl(x))	'Callback
				If UseCallBack(x) then Proc name & x,Lvl(x)*mult(x)	'Proc
				If Lock(x) Then
					if Lvl(x) = 1 or Lvl(x) = 0 then Loaded(x) = True	'finished fading
				end if
			end if
		Next
	End Sub
End Class




'version 0.11 - Mass Assign, Changed modulate style
'version 0.12 - Update2 (single -1 timer update) update method for core.vbs
'Version 0.12a - Filter can now be publicly accessed via 'FilterOut'
'Version 0.12b - Changed MassAssign from a sub to an indexed property (new syntax: lampfader.MassAssign(15) = Light1 )
'Version 0.13 - No longer requires setlocale. Callback() can be assigned multiple times per index
'Version 0.13a - fixed DynamicLamps hopefully
' Note: if using multiple 'DynamicLamps' objects, change the 'name' variable to avoid conflicts with callbacks

Class DynamicLamps 'Lamps that fade up and down. GI and Flasher handling
	Public Loaded(50), FadeSpeedDown(50), FadeSpeedUp(50)
	Private Lock(50), SolModValue(50)
	Private UseCallback(50), cCallback(50)
	Public Lvl(50)
	Public Obj(50)
	Private UseFunction, cFilter
	private Mult(50)
	Public Name

	Public FrameTime
	Private InitFrame

	Private Sub Class_Initialize()
		InitFrame = 0
		dim x : for x = 0 to uBound(Obj)
			FadeSpeedup(x) = 0.01
			FadeSpeedDown(x) = 0.01
			lvl(x) = 0.0001 : SolModValue(x) = 0
			Lock(x) = True : Loaded(x) = False
			mult(x) = 1
			Name = "DynamicFaderNF" 'NEEDS TO BE CHANGED IF THERE'S MULTIPLE OBJECTS, OTHERWISE CALLBACKS WILL INTERFERE WITH EACH OTHER!!
			if IsEmpty(obj(x) ) then Set Obj(x) = NullFader' : Loaded(x) = True
		next
	End Sub

	Public Property Get Locked(idx) : Locked = Lock(idx) : End Property
	'Public Property Let Callback(idx, String) : cCallback(idx) = String : UseCallBack(idx) = True : End Property
	Public Property Let Filter(String) : Set cFilter = GetRef(String) : UseFunction = True : End Property
	Public Function FilterOut(aInput) : if UseFunction Then FilterOut = cFilter(aInput) Else FilterOut = aInput End If : End Function

	Public Property Let Callback(idx, String)
		UseCallBack(idx) = True
		'cCallback(idx) = String 'old execute method
		'New method: build wrapper subs using ExecuteGlobal, then call them
		cCallback(idx) = cCallback(idx) & "___" & String	'multiple strings dilineated by 3x _

		dim tmp : tmp = Split(cCallback(idx), "___")

		dim str, x : for x = 0 to uBound(tmp)	'build proc contents
			'debugstr = debugstr & x & "=" & tmp(x) & vbnewline
			'If Not tmp(x)="" then str = str & "	" & tmp(x) & " aLVL" & "	'" & x & vbnewline	'more verbose
			If Not tmp(x)="" then str = str & tmp(x) & " aLVL:"
		Next

		dim out : out = "Sub " & name & idx & "(aLvl):" & str & "End Sub"
		'if idx = 132 then msgbox out	'debug
		ExecuteGlobal Out

	End Property


	Public Property Let State(idx,Value)
		'If Value = SolModValue(idx) Then Exit Property ' Discard redundant updates
		If Value <> SolModValue(idx) Then ' Discard redundant updates
			SolModValue(idx) = Value
			Lock(idx) = False : Loaded(idx) = False
		End If
	End Property
	Public Property Get state(idx) : state = SolModValue(idx) : end Property

	'Mass assign, Builds arrays where necessary
	'Sub MassAssign(aIdx, aInput)
	Public Property Let MassAssign(aIdx, aInput)
		If typename(obj(aIdx)) = "NullFadingObject" Then 'if empty, use Set
			if IsArray(aInput) then
				obj(aIdx) = aInput
			Else
				Set obj(aIdx) = aInput
			end if
		Else
			Obj(aIdx) = AppendArray(obj(aIdx), aInput)
		end if
	end Property

	'solcallback (solmodcallback) handler
	Sub SetLamp(aIdx, aInput) : state(aIdx) = aInput : End Sub	'0->1 Input
	Sub SetModLamp(aIdx, aInput) : state(aIdx) = aInput/255 : End Sub	'0->255 Input
	Sub SetGI(aIdx, ByVal aInput) : if aInput = 8 then aInput = 7 end if : state(aIdx) = aInput/7 : End Sub	'0->8 WPC GI input

	Public Sub TurnOnStates()	'If obj contains any light objects, set their states to 1 (Fading is our job!)
		dim debugstr
		dim idx : for idx = 0 to uBound(obj)
			if IsArray(obj(idx)) then
				'debugstr = debugstr & "array found at " & idx & "..."
				dim x, tmp : tmp = obj(idx) 'set tmp to array in order to access it
				for x = 0 to uBound(tmp)
					if typename(tmp(x)) = "Light" then DisableState tmp(x) ': debugstr = debugstr & tmp(x).name & " state'd" & vbnewline

				Next
			Else
				if typename(obj(idx)) = "Light" then DisableState obj(idx) ': debugstr = debugstr & obj(idx).name & " state'd (not array)" & vbnewline

			end if
		Next
		'debug.print debugstr
	End Sub
	Private Sub DisableState(ByRef aObj) : aObj.FadeSpeedUp = 1000 : aObj.State = 1 : End Sub	'turn state to 1

	Public Sub Init()	'just call turnonstates for now
		TurnOnStates
	End Sub

	Public Property Let Modulate(aIdx, aCoef) : Mult(aIdx) = aCoef : Lock(aIdx) = False : Loaded(aIdx) = False: End Property
	Public Property Get Modulate(aIdx) : Modulate = Mult(aIdx) : End Property

	Public Sub Update1()	 'Handle all numeric fading. If done fading, Lock(x) = True
		'dim stringer
		dim x : for x = 0 to uBound(Lvl)
			'stringer = "Locked @ " & SolModValue(x)
			if not Lock(x) then 'and not Loaded(x) then
				If lvl(x) < SolModValue(x) then '+
					'stringer = "Fading Up " & lvl(x) & " + " & FadeSpeedUp(x)
					Lvl(x) = Lvl(x) + FadeSpeedUp(x)
					if Lvl(x) >= SolModValue(x) then Lvl(x) = SolModValue(x) : Lock(x) = True
				ElseIf Lvl(x) > SolModValue(x) Then '-
					Lvl(x) = Lvl(x) - FadeSpeedDown(x)
					'stringer = "Fading Down " & lvl(x) & " - " & FadeSpeedDown(x)
					if Lvl(x) <= SolModValue(x) then Lvl(x) = SolModValue(x) : Lock(x) = True
				End If
			end if
		Next
		'tbF.text = stringer
	End Sub

	Public Sub Update2()	 'Both updates on -1 timer (Lowest latency, but less accurate fading at 60fps vsync)
		FrameTime = gametime - InitFrame : InitFrame = GameTime	'Calculate frametime
		dim x : for x = 0 to uBound(Lvl)
			if not Lock(x) then 'and not Loaded(x) then
				If lvl(x) < SolModValue(x) then '+
					Lvl(x) = Lvl(x) + FadeSpeedUp(x) * FrameTime
					if Lvl(x) >= SolModValue(x) then Lvl(x) = SolModValue(x) : Lock(x) = True
				ElseIf Lvl(x) > SolModValue(x) Then '-
					Lvl(x) = Lvl(x) - FadeSpeedDown(x) * FrameTime
					if Lvl(x) <= SolModValue(x) then Lvl(x) = SolModValue(x) : Lock(x) = True
				End If
			end if
		Next
		Update
	End Sub

	Public Sub Update()	'Handle object updates. Update on a -1 Timer! If done fading, loaded(x) = True
		dim x,xx
		for x = 0 to uBound(Lvl)
			if not Loaded(x) then
				if IsArray(obj(x) ) Then	'if array
					If UseFunction then
						for each xx in obj(x) : xx.IntensityScale = cFilter(abs(Lvl(x))*mult(x)) : Next
					Else
						for each xx in obj(x) : xx.IntensityScale = Lvl(x)*mult(x) : Next
					End If
				else						'if single lamp or flasher
					If UseFunction then
						obj(x).Intensityscale = cFilter(abs(Lvl(x))*mult(x))
					Else
						obj(x).Intensityscale = Lvl(x)*mult(x)
					End If
				end if
				'If UseCallBack(x) then execute cCallback(x) & " " & (Lvl(x)*mult(x))	'Callback
				If UseCallBack(x) then Proc name & x,Lvl(x)*mult(x)	'Proc
				If Lock(x) Then
					Loaded(x) = True
				end if
			end if
		Next
	End Sub
End Class

'Helper functions
Sub Proc(string, Callback)	'proc using a string and one argument
	'On Error Resume Next
	dim p : Set P = GetRef(String)
	P Callback
	If err.number = 13 then  msgbox "Proc error! No such procedure: " & vbnewline & string
	if err.number = 424 then msgbox "Proc error! No such Object"
End Sub

Function AppendArray(ByVal aArray, aInput)	'append one value, object, or Array onto the end of a 1 dimensional array
	if IsArray(aInput) then 'Input is an array...
		dim tmp : tmp = aArray
		If not IsArray(aArray) Then	'if not array, create an array
			tmp = aInput
		Else						'Append existing array with aInput array
			Redim Preserve tmp(uBound(aArray) + uBound(aInput)+1)	'If existing array, increase bounds by uBound of incoming array
			dim x : for x = 0 to uBound(aInput)
				if isObject(aInput(x)) then
					Set tmp(x+uBound(aArray)+1 ) = aInput(x)
				Else
					tmp(x+uBound(aArray)+1 ) = aInput(x)
				End If
			Next
		AppendArray = tmp	 'return new array
		End If
	Else 'Input is NOT an array...
		If not IsArray(aArray) Then	'if not array, create an array
			aArray = Array(aArray, aInput)
		Else
			Redim Preserve aArray(uBound(aArray)+1)	'If array, increase bounds by 1
			if isObject(aInput) then
				Set aArray(uBound(aArray)) = aInput
			Else
				aArray(uBound(aArray)) = aInput
			End If
		End If
		AppendArray = aArray 'return new array
	End If
End Function


'******************************************************
'****  END LAMPZ
'******************************************************

'////////////////////////////  MECHANICAL SOUNDS  ///////////////////////////
'//  This part in the script is an entire block that is dedicated to the physics sound system.
'//  Various scripts and sounds that may be pretty generic and could suit other WPC systems, but the most are tailored specifically for this table.

'///////////////////////////////  SOUNDS PARAMETERS  //////////////////////////////
Dim GlobalSoundLevel, CoinSoundLevel, PlungerReleaseSoundLevel, PlungerPullSoundLevel, NudgeLeftSoundLevel
Dim NudgeRightSoundLevel, NudgeCenterSoundLevel, StartButtonSoundLevel, RollingSoundFactor

GlobalSoundLevel = 3
CoinSoundLevel = 1														'volume level; range [0, 1]
NudgeLeftSoundLevel = 1													'volume level; range [0, 1]
NudgeRightSoundLevel = 1												'volume level; range [0, 1]
NudgeCenterSoundLevel = 1												'volume level; range [0, 1]
StartButtonSoundLevel = 0.1												'volume level; range [0, 1]
PlungerReleaseSoundLevel = 0.8 '1 wjr									'volume level; range [0, 1]
PlungerPullSoundLevel = 1												'volume level; range [0, 1]
RollingSoundFactor = 1.1/5		

'///////////////////////-----Solenoids, Kickers and Flash Relays-----///////////////////////
Dim FlipperUpAttackMinimumSoundLevel, FlipperUpAttackMaximumSoundLevel, FlipperUpAttackLeftSoundLevel, FlipperUpAttackRightSoundLevel
Dim FlipperUpSoundLevel, FlipperDownSoundLevel, FlipperLeftHitParm, FlipperRightHitParm
Dim SlingshotSoundLevel, BumperSoundFactor, KnockerSoundLevel, RelayFlashSoundLevel, RelayGISoundLevel

FlipperUpAttackMinimumSoundLevel = 0.010           						'volume level; range [0, 1]
FlipperUpAttackMaximumSoundLevel = 0.635								'volume level; range [0, 1]
FlipperUpSoundLevel = 1.0                        						'volume level; range [0, 1]
FlipperDownSoundLevel = 0.45                      						'volume level; range [0, 1]
FlipperLeftHitParm = FlipperUpSoundLevel								'sound helper; not configurable
FlipperRightHitParm = FlipperUpSoundLevel								'sound helper; not configurable
SlingshotSoundLevel = 1												'volume level; range [0, 1]
BumperSoundFactor = 5												'volume multiplier; must not be zero
KnockerSoundLevel = 1 													'volume level; range [0, 1]
RelayFlashSoundLevel = 0.0075 * GlobalSoundLevel * 14						'volume level; range [0, 1];
RelayGISoundLevel = 0.025 * GlobalSoundLevel * 14						'volume level; range [0, 1];

'///////////////////////-----Ball Drops, Bumps and Collisions-----///////////////////////
Dim RubberStrongSoundFactor, RubberWeakSoundFactor, RubberFlipperSoundFactor,BallWithBallCollisionSoundFactor
Dim BallBouncePlayfieldSoftFactor, BallBouncePlayfieldHardFactor, PlasticRampDropToPlayfieldSoundLevel, WireRampDropToPlayfieldSoundLevel, DelayedBallDropOnPlayfieldSoundLevel
Dim WallImpactSoundFactor, MetalImpactSoundFactor, SubwaySoundLevel, SubwayEntrySoundLevel, ScoopEntrySoundLevel
Dim SaucerLockSoundLevel, SaucerKickSoundLevel

BallWithBallCollisionSoundFactor = 3.2									'volume multiplier; must not be zero
RubberStrongSoundFactor = 0.055/5											'volume multiplier; must not be zero
RubberWeakSoundFactor = 0.075/5											'volume multiplier; must not be zero
RubberFlipperSoundFactor = 0.075/5										'volume multiplier; must not be zero
BallBouncePlayfieldSoftFactor = 0.025									'volume multiplier; must not be zero
BallBouncePlayfieldHardFactor = 0.025									'volume multiplier; must not be zero
DelayedBallDropOnPlayfieldSoundLevel = 0.8									'volume level; range [0, 1]
WallImpactSoundFactor = 0.075											'volume multiplier; must not be zero
MetalImpactSoundFactor = 0.075/3
SaucerLockSoundLevel = 0.8
SaucerKickSoundLevel = 0.8

'///////////////////////-----Gates, Spinners, Rollovers and Targets-----///////////////////////

Dim GateSoundLevel, TargetSoundFactor, SpinnerSoundLevel, RolloverSoundLevel, DTSoundLevel

GateSoundLevel = 0.5/5													'volume level; range [0, 1]
TargetSoundFactor = 0.0025 * 10											'volume multiplier; must not be zero
DTSoundLevel = 0.25														'volume multiplier; must not be zero
RolloverSoundLevel = 0.25                              					'volume level; range [0, 1]

'///////////////////////-----Ball Release, Guides and Drain-----///////////////////////
Dim DrainSoundLevel, BallReleaseSoundLevel, BottomArchBallGuideSoundFactor, FlipperBallGuideSoundFactor 

DrainSoundLevel = 0.8														'volume level; range [0, 1]
BallReleaseSoundLevel = 1												'volume level; range [0, 1]
BottomArchBallGuideSoundFactor = 0.2									'volume multiplier; must not be zero
FlipperBallGuideSoundFactor = 0.015										'volume multiplier; must not be zero

'///////////////////////-----Loops and Lanes-----///////////////////////
Dim ArchSoundFactor
ArchSoundFactor = 0.025/5													'volume multiplier; must not be zero


'/////////////////////////////  SOUND PLAYBACK FUNCTIONS  ////////////////////////////
'/////////////////////////////  POSITIONAL SOUND PLAYBACK METHODS  ////////////////////////////
' Positional sound playback methods will play a sound, depending on the X,Y position of the table element or depending on ActiveBall object position
' These are similar subroutines that are less complicated to use (e.g. simply use standard parameters for the PlaySound call)
' For surround setup - positional sound playback functions will fade between front and rear surround channels and pan between left and right channels
' For stereo setup - positional sound playback functions will only pan between left and right channels
' For mono setup - positional sound playback functions will not pan between left and right channels and will not fade between front and rear channels

' PlaySound full syntax - PlaySound(string, int loopcount, float volume, float pan, float randompitch, int pitch, bool useexisting, bool restart, float front_rear_fade)
' Note - These functions will not work (currently) for walls/slingshots as these do not feature a simple, single X,Y position
Sub PlaySoundAtLevelStatic(playsoundparams, aVol, tableobj)
    PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(tableobj), 0, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtLevelExistingStatic(playsoundparams, aVol, tableobj)
    PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(tableobj), 0, 0, 1, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtLevelStaticLoop(playsoundparams, aVol, tableobj)
    PlaySound playsoundparams, -1, aVol * VolumeDial, AudioPan(tableobj), 0, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtLevelStaticRandomPitch(playsoundparams, aVol, randomPitch, tableobj)
    PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(tableobj), randomPitch, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtLevelActiveBall(playsoundparams, aVol)
	PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(ActiveBall), 0, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub PlaySoundAtLevelExistingActiveBall(playsoundparams, aVol)
	PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(ActiveBall), 0, 0, 1, 0, AudioFade(ActiveBall)
End Sub

Sub PlaySoundAtLeveTimerActiveBall(playsoundparams, aVol, ballvariable)
	PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(ballvariable), 0, 0, 0, 0, AudioFade(ballvariable)
End Sub

Sub PlaySoundAtLevelTimerExistingActiveBall(playsoundparams, aVol, ballvariable)
	PlaySound playsoundparams, 0, aVol * VolumeDial, AudioPan(ballvariable), 0, 0, 1, 0, AudioFade(ballvariable)
End Sub

Sub PlaySoundAtLevelRoll(playsoundparams, aVol, pitch)
    PlaySound playsoundparams, -1, aVol * VolumeDial, AudioPan(tableobj), randomPitch, 0, 0, 0, AudioFade(tableobj)
End Sub

' Previous Positional Sound Subs

Sub PlaySoundAt(soundname, tableobj)
    PlaySound soundname, 1, 1 * VolumeDial, AudioPan(tableobj), 0,0,0, 1, AudioFade(tableobj)
End Sub

Sub PlaySoundAtVol(soundname, tableobj, aVol)
    PlaySound soundname, 1, aVol * VolumeDial, AudioPan(tableobj), 0,0,0, 1, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname)
    PlaySoundAt soundname, ActiveBall
End Sub

Sub PlaySoundAtBallVol (Soundname, aVol)
	Playsound soundname, 1,aVol * VolumeDial, AudioPan(ActiveBall), 0,0,0, 1, AudioFade(ActiveBall)
End Sub

Sub PlaySoundAtBallVolM (Soundname, aVol)
	Playsound soundname, 1,aVol * VolumeDial, AudioPan(ActiveBall), 0,0,0, 0, AudioFade(ActiveBall)
End Sub

Sub PlaySoundAtVolLoops(sound, tableobj, Vol, Loops)
	PlaySound sound, Loops, Vol * VolumeDial, AudioPan(tableobj), 0,0,0, 1, AudioFade(tableobj)
End Sub


' *********************************************************************
'                     Fleep  Supporting Ball & Sound Functions
' *********************************************************************

Function AudioFade(tableobj) ' Fades between front and back of the table (for surround systems or 2x2 speakers, etc), depending on the Y position on the table. "table1" is the name of the table
	Dim tmp
	tmp = tableobj.y * 2 / tableheight-1

	if tmp > 7000 Then
		tmp = 7000
	elseif tmp < -7000 Then
		tmp = -7000
	end if

    	If tmp > 0 Then
		AudioFade = Csng(tmp ^10)
	Else
		AudioFade = Csng(-((- tmp) ^10) )
	End If
End Function

Function AudioPan(tableobj) ' Calculates the pan for a tableobj based on the X position on the table. "table1" is the name of the table
	Dim tmp
	tmp = tableobj.x * 2 / tablewidth-1

	if tmp > 7000 Then
		tmp = 7000
	elseif tmp < -7000 Then
		tmp = -7000
	end if

	If tmp > 0 Then
		AudioPan = Csng(tmp ^10)
	Else
		AudioPan = Csng(-((- tmp) ^10) )
	End If
End Function

Function Vol(ball) ' Calculates the volume of the sound based on the ball speed
	Vol = Csng(BallVel(ball) ^2)
End Function

Function Volz(ball) ' Calculates the volume of the sound based on the ball speed
	Volz = Csng((ball.velz) ^2)
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = INT(SQR((ball.VelX ^2) + (ball.VelY ^2) ) )
End Function

Function VolPlayfieldRoll(ball) ' Calculates the roll volume of the sound based on the ball speed
	VolPlayfieldRoll = RollingSoundFactor * 0.0005 * Csng(BallVel(ball) ^3)
End Function

Function PitchPlayfieldRoll(ball) ' Calculates the roll pitch of the sound based on the ball speed
    PitchPlayfieldRoll = BallVel(ball) ^2 * 15
End Function

Function RndInt(min, max)
    RndInt = Int(Rnd() * (max-min + 1) + min)' Sets a random number integer between min and max
End Function

Function RndNum(min, max)
    RndNum = Rnd() * (max-min) + min' Sets a random number between min and max
End Function

'/////////////////////////////  GENERAL SOUND SUBROUTINES  ////////////////////////////
Sub SoundStartButton()
	PlaySound ("Start_Button"), 0, StartButtonSoundLevel, 0, 0.25
End Sub

Sub SoundNudgeLeft()
	PlaySound ("Nudge_" & Int(Rnd*2)+1), 0, NudgeLeftSoundLevel * VolumeDial, -0.1, 0.25
End Sub

Sub SoundNudgeRight()
	PlaySound ("Nudge_" & Int(Rnd*2)+1), 0, NudgeRightSoundLevel * VolumeDial, 0.1, 0.25
End Sub

Sub SoundNudgeCenter()
	PlaySound ("Nudge_" & Int(Rnd*2)+1), 0, NudgeCenterSoundLevel * VolumeDial, 0, 0.25
End Sub


Sub SoundPlungerPull()
	PlaySoundAtLevelStatic ("Plunger_Pull_1"), PlungerPullSoundLevel, Plunger
End Sub

Sub SoundPlungerReleaseBall()
	PlaySoundAtLevelStatic ("Plunger_Release_Ball"), PlungerReleaseSoundLevel, Plunger	
End Sub

Sub SoundPlungerReleaseNoBall()
	PlaySoundAtLevelStatic ("Plunger_Release_No_Ball"), PlungerReleaseSoundLevel, Plunger
End Sub


'/////////////////////////////  KNOCKER SOLENOID  ////////////////////////////
Sub KnockerSolenoid()
	PlaySoundAtLevelStatic SoundFX("bell",DOFBell), KnockerSoundLevel, KnockerPosition
End Sub

'/////////////////////////////  DRAIN SOUNDS  ////////////////////////////
Sub RandomSoundDrain(drainswitch)
	PlaySoundAtLevelStatic ("Drain_" & Int(Rnd*11)+1), DrainSoundLevel, drainswitch
End Sub

'/////////////////////////////  TROUGH BALL RELEASE SOLENOID SOUNDS  ////////////////////////////

Sub RandomSoundBallRelease(drainswitch)
	PlaySoundAtLevelStatic SoundFX("BallRelease" & Int(Rnd*7)+1,DOFContactors), BallReleaseSoundLevel, drainswitch
End Sub

'/////////////////////////////  SLINGSHOT SOLENOID SOUNDS  ////////////////////////////
Sub RandomSoundSlingshotLeft(sling)
	PlaySoundAtLevelStatic SoundFX("Sling_L" & Int(Rnd*10)+1,DOFContactors), SlingshotSoundLevel, Sling
End Sub

Sub RandomSoundSlingshotRight(sling)
	PlaySoundAtLevelStatic SoundFX("Sling_R" & Int(Rnd*8)+1,DOFContactors), SlingshotSoundLevel, Sling
End Sub

'/////////////////////////////  BUMPER SOLENOID SOUNDS  ////////////////////////////
Sub RandomSoundBumperTop(Bump)
	PlaySoundAtLevelStatic SoundFX("Bumpers_Top_" & Int(Rnd*5)+1,DOFContactors), Vol(ActiveBall) * BumperSoundFactor, Bump
End Sub

Sub RandomSoundBumperMiddle(Bump)
	PlaySoundAtLevelStatic SoundFX("Bumpers_Middle_" & Int(Rnd*5)+1,DOFContactors), Vol(ActiveBall) * BumperSoundFactor, Bump
End Sub

Sub RandomSoundBumperBottom(Bump)
	PlaySoundAtLevelStatic SoundFX("Bumpers_Bottom_" & Int(Rnd*5)+1,DOFContactors), Vol(ActiveBall) * BumperSoundFactor, Bump
End Sub

'/////////////////////////////  FLIPPER BATS SOUND SUBROUTINES  ////////////////////////////
'/////////////////////////////  FLIPPER BATS SOLENOID ATTACK SOUND  ////////////////////////////
Sub SoundFlipperUpAttackLeft(flipper)
	FlipperUpAttackLeftSoundLevel = RndNum(FlipperUpAttackMinimumSoundLevel, FlipperUpAttackMaximumSoundLevel)
	PlaySoundAtLevelStatic ("Flipper_Attack-L01"), FlipperUpAttackLeftSoundLevel, flipper
End Sub

Sub SoundFlipperUpAttackRight(flipper)
	FlipperUpAttackRightSoundLevel = RndNum(FlipperUpAttackMinimumSoundLevel, FlipperUpAttackMaximumSoundLevel)
		PlaySoundAtLevelStatic ("Flipper_Attack-R01"), FlipperUpAttackLeftSoundLevel, flipper
End Sub

'/////////////////////////////  FLIPPER BATS SOLENOID CORE SOUND  ////////////////////////////
Sub RandomSoundFlipperUpLeft(flipper)
	PlaySoundAtLevelStatic SoundFX("Flipper_L0" & Int(Rnd*9)+1,DOFFlippers), FlipperLeftHitParm, Flipper
End Sub

Sub RandomSoundFlipperUpRight(flipper)
	PlaySoundAtLevelStatic SoundFX("Flipper_R0" & Int(Rnd*9)+1,DOFFlippers), FlipperRightHitParm, Flipper
End Sub

Sub RandomSoundReflipUpLeft(flipper)
	PlaySoundAtLevelStatic SoundFX("Flipper_ReFlip_L0" & Int(Rnd*3)+1,DOFFlippers), (RndNum(0.8, 1))*FlipperUpSoundLevel, Flipper
End Sub

Sub RandomSoundReflipUpRight(flipper)
	PlaySoundAtLevelStatic SoundFX("Flipper_ReFlip_R0" & Int(Rnd*3)+1,DOFFlippers), (RndNum(0.8, 1))*FlipperUpSoundLevel, Flipper
End Sub

Sub RandomSoundFlipperDownLeft(flipper)
	PlaySoundAtLevelStatic SoundFX("Flipper_Left_Down_" & Int(Rnd*7)+1,DOFFlippers), FlipperDownSoundLevel, Flipper
End Sub

Sub RandomSoundFlipperDownRight(flipper)
	PlaySoundAtLevelStatic SoundFX("Flipper_Right_Down_" & Int(Rnd*8)+1,DOFFlippers), FlipperDownSoundLevel, Flipper
End Sub

'/////////////////////////////  FLIPPER BATS BALL COLLIDE SOUND  ////////////////////////////

Sub LeftFlipperCollide(parm)
	FlipperLeftHitParm = parm/10
	If FlipperLeftHitParm > 1 Then
		FlipperLeftHitParm = 1
	End If
	FlipperLeftHitParm = FlipperUpSoundLevel * FlipperLeftHitParm
	RandomSoundRubberFlipper(parm)
End Sub

Sub RightFlipperCollide(parm)
	FlipperRightHitParm = parm/10
	If FlipperRightHitParm > 1 Then
		FlipperRightHitParm = 1
	End If
	FlipperRightHitParm = FlipperUpSoundLevel * FlipperRightHitParm
 	RandomSoundRubberFlipper(parm)
End Sub

Sub RandomSoundRubberFlipper(parm)
	PlaySoundAtLevelActiveBall ("Flipper_Rubber_" & Int(Rnd*7)+1), parm  * RubberFlipperSoundFactor
End Sub

'/////////////////////////////  ROLLOVER SOUNDS  ////////////////////////////
Sub RandomSoundRollover()
	PlaySoundAtLevelActiveBall ("Rollover_" & Int(Rnd*4)+1), RolloverSoundLevel
End Sub

Sub Rollovers_Hit(idx)
	RandomSoundRollover
End Sub

'/////////////////////////////  VARIOUS PLAYFIELD SOUND SUBROUTINES  ////////////////////////////
'/////////////////////////////  RUBBERS AND POSTS  ////////////////////////////
'/////////////////////////////  RUBBERS - EVENTS  ////////////////////////////
Sub Rubbers_Hit(idx)
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 5 then		
 		RandomSoundRubberStrong 1
	End if
	If finalspeed <= 5 then
 		RandomSoundRubberWeak()
 	End If	
End Sub

'/////////////////////////////  RUBBERS AND POSTS - STRONG IMPACTS  ////////////////////////////
Sub RandomSoundRubberStrong(voladj)
	Select Case Int(Rnd*10)+1
		Case 1 : PlaySoundAtLevelActiveBall ("Rubber_Strong_1"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 2 : PlaySoundAtLevelActiveBall ("Rubber_Strong_2"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 3 : PlaySoundAtLevelActiveBall ("Rubber_Strong_3"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 4 : PlaySoundAtLevelActiveBall ("Rubber_Strong_4"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 5 : PlaySoundAtLevelActiveBall ("Rubber_Strong_5"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 6 : PlaySoundAtLevelActiveBall ("Rubber_Strong_6"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 7 : PlaySoundAtLevelActiveBall ("Rubber_Strong_7"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 8 : PlaySoundAtLevelActiveBall ("Rubber_Strong_8"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 9 : PlaySoundAtLevelActiveBall ("Rubber_Strong_9"), Vol(ActiveBall) * RubberStrongSoundFactor*voladj
		Case 10 : PlaySoundAtLevelActiveBall ("Rubber_1_Hard"), Vol(ActiveBall) * RubberStrongSoundFactor * 0.6*voladj
	End Select
End Sub

'/////////////////////////////  RUBBERS AND POSTS - WEAK IMPACTS  ////////////////////////////
Sub RandomSoundRubberWeak()
	PlaySoundAtLevelActiveBall ("Rubber_" & Int(Rnd*9)+1), Vol(ActiveBall) * RubberWeakSoundFactor
End Sub

'/////////////////////////////  WALL IMPACTS  ////////////////////////////
Sub Walls_Hit(idx)
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 5 then
 		RandomSoundRubberStrong 1 
	End if
	If finalspeed <= 5 then
 		RandomSoundRubberWeak()
 	End If	
End Sub

Sub RandomSoundWall()
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 16 then 
		Select Case Int(Rnd*5)+1
			Case 1 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_1"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 2 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_2"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 3 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_5"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 4 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_7"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 5 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_9"), Vol(ActiveBall) * WallImpactSoundFactor
		End Select
	End if
	If finalspeed >= 6 AND finalspeed <= 16 then
		Select Case Int(Rnd*4)+1
			Case 1 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_3"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 2 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_4"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 3 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_6"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 4 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_8"), Vol(ActiveBall) * WallImpactSoundFactor
		End Select
 	End If
	If finalspeed < 6 Then
		Select Case Int(Rnd*3)+1
			Case 1 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_4"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 2 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_6"), Vol(ActiveBall) * WallImpactSoundFactor
			Case 3 : PlaySoundAtLevelExistingActiveBall ("Wall_Hit_8"), Vol(ActiveBall) * WallImpactSoundFactor
		End Select
	End if
End Sub

'/////////////////////////////  METAL TOUCH SOUNDS  ////////////////////////////
Sub RandomSoundMetal()
	PlaySoundAtLevelActiveBall ("Metal_Touch_" & Int(Rnd*13)+1), Vol(ActiveBall) * MetalImpactSoundFactor
End Sub

'/////////////////////////////  METAL - EVENTS  ////////////////////////////

Sub Metals_Hit (idx)
	RandomSoundMetal
End Sub

Sub ShooterDiverter_collide(idx)
	RandomSoundMetal
End Sub

'/////////////////////////////  BOTTOM ARCH BALL GUIDE  ////////////////////////////
'/////////////////////////////  BOTTOM ARCH BALL GUIDE - SOFT BOUNCES  ////////////////////////////
Sub RandomSoundBottomArchBallGuide()
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 16 then 
		PlaySoundAtLevelActiveBall ("Apron_Bounce_"& Int(Rnd*2)+1), Vol(ActiveBall) * BottomArchBallGuideSoundFactor
	End if
	If finalspeed >= 6 AND finalspeed <= 16 then
 		Select Case Int(Rnd*2)+1
			Case 1 : PlaySoundAtLevelActiveBall ("Apron_Bounce_1"), Vol(ActiveBall) * BottomArchBallGuideSoundFactor
			Case 2 : PlaySoundAtLevelActiveBall ("Apron_Bounce_Soft_1"), Vol(ActiveBall) * BottomArchBallGuideSoundFactor
		End Select
 	End If
	If finalspeed < 6 Then
 		Select Case Int(Rnd*2)+1
			Case 1 : PlaySoundAtLevelActiveBall ("Apron_Bounce_Soft_1"), Vol(ActiveBall) * BottomArchBallGuideSoundFactor
			Case 2 : PlaySoundAtLevelActiveBall ("Apron_Medium_3"), Vol(ActiveBall) * BottomArchBallGuideSoundFactor
		End Select
	End if
End Sub

'/////////////////////////////  BOTTOM ARCH BALL GUIDE - HARD HITS  ////////////////////////////
Sub RandomSoundBottomArchBallGuideHardHit()
	PlaySoundAtLevelActiveBall ("Apron_Hard_Hit_" & Int(Rnd*3)+1), BottomArchBallGuideSoundFactor * 0.25
End Sub

Sub Apron_Hit (idx)
	If Abs(cor.ballvelx(activeball.id) < 4) and cor.ballvely(activeball.id) > 7 then
		RandomSoundBottomArchBallGuideHardHit()
	Else
		RandomSoundBottomArchBallGuide
	End If
End Sub

'/////////////////////////////  FLIPPER BALL GUIDE  ////////////////////////////
Sub RandomSoundFlipperBallGuide()
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 16 then 
 		Select Case Int(Rnd*2)+1
			Case 1 : PlaySoundAtLevelActiveBall ("Apron_Hard_1"),  Vol(ActiveBall) * FlipperBallGuideSoundFactor
			Case 2 : PlaySoundAtLevelActiveBall ("Apron_Hard_2"),  Vol(ActiveBall) * 0.8 * FlipperBallGuideSoundFactor
		End Select
	End if
	If finalspeed >= 6 AND finalspeed <= 16 then
		PlaySoundAtLevelActiveBall ("Apron_Medium_" & Int(Rnd*3)+1),  Vol(ActiveBall) * FlipperBallGuideSoundFactor
 	End If
	If finalspeed < 6 Then
		PlaySoundAtLevelActiveBall ("Apron_Soft_" & Int(Rnd*7)+1),  Vol(ActiveBall) * FlipperBallGuideSoundFactor
	End If
End Sub

'/////////////////////////////  TARGET HIT SOUNDS  ////////////////////////////
Sub RandomSoundTargetHitStrong()
	PlaySoundAtLevelActiveBall SoundFX("Target_Hit_" & Int(Rnd*4)+5,DOFTargets), Vol(ActiveBall) * 0.45 * TargetSoundFactor
End Sub

Sub RandomSoundTargetHitWeak()		
	PlaySoundAtLevelActiveBall SoundFX("Target_Hit_" & Int(Rnd*4)+1,DOFTargets), Vol(ActiveBall) * TargetSoundFactor
End Sub

Sub PlayTargetSound()
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 10 then
 		RandomSoundTargetHitStrong()
		RandomSoundBallBouncePlayfieldSoft Activeball
	Else 
 		RandomSoundTargetHitWeak()
 	End If	
End Sub

Sub Targets_Hit (idx)
	PlayTargetSound	
	TargetBouncer Activeball, 1	
End Sub

'/////////////////////////////  BALL BOUNCE SOUNDS  ////////////////////////////
Sub RandomSoundBallBouncePlayfieldSoft(aBall)
	Select Case Int(Rnd*9)+1
		Case 1 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Soft_1"), volz(aBall) * BallBouncePlayfieldSoftFactor, aBall
		Case 2 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Soft_2"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.5, aBall
		Case 3 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Soft_3"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.8, aBall
		Case 4 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Soft_4"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.5, aBall
		Case 5 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Soft_5"), volz(aBall) * BallBouncePlayfieldSoftFactor, aBall
		Case 6 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Hard_1"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.2, aBall
		Case 7 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Hard_2"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.2, aBall
		Case 8 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Hard_5"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.2, aBall
		Case 9 : PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Hard_7"), volz(aBall) * BallBouncePlayfieldSoftFactor * 0.3, aBall
	End Select
End Sub

Sub RandomSoundBallBouncePlayfieldHard(aBall)
	PlaySoundAtLevelStatic ("Ball_Bounce_Playfield_Hard_" & Int(Rnd*7)+1), volz(aBall) * BallBouncePlayfieldHardFactor, aBall
End Sub

'/////////////////////////////  DELAYED DROP - TO PLAYFIELD - SOUND  ////////////////////////////
Sub RandomSoundDelayedBallDropOnPlayfield(aBall)
	Select Case Int(Rnd*5)+1
		Case 1 : PlaySoundAtLevelStatic ("Ball_Drop_Playfield_1_Delayed"), DelayedBallDropOnPlayfieldSoundLevel, aBall
		Case 2 : PlaySoundAtLevelStatic ("Ball_Drop_Playfield_2_Delayed"), DelayedBallDropOnPlayfieldSoundLevel, aBall
		Case 3 : PlaySoundAtLevelStatic ("Ball_Drop_Playfield_3_Delayed"), DelayedBallDropOnPlayfieldSoundLevel, aBall
		Case 4 : PlaySoundAtLevelStatic ("Ball_Drop_Playfield_4_Delayed"), DelayedBallDropOnPlayfieldSoundLevel, aBall
		Case 5 : PlaySoundAtLevelStatic ("Ball_Drop_Playfield_5_Delayed"), DelayedBallDropOnPlayfieldSoundLevel, aBall
	End Select
End Sub

'/////////////////////////////  BALL GATES AND BRACKET GATES SOUNDS  ////////////////////////////

Sub SoundPlayfieldGate()			
	PlaySoundAtLevelStatic ("Gate_FastTrigger_" & Int(Rnd*2)+1), GateSoundLevel, Activeball
End Sub

Sub SoundHeavyGate()
	PlaySoundAtLevelStatic ("Gate_2"), GateSoundLevel, Activeball
End Sub

Sub Gates_hit(idx)
	SoundHeavyGate
End Sub

Sub GatesWire_hit(idx)	
	SoundPlayfieldGate	
End Sub	

'/////////////////////////////  LEFT LANE ENTRANCE - SOUNDS  ////////////////////////////

Sub RandomSoundLeftArch()
	PlaySoundAtLevelActiveBall ("Arch_L" & Int(Rnd*4)+1), Vol(ActiveBall) * ArchSoundFactor
End Sub

Sub RandomSoundRightArch()
	PlaySoundAtLevelActiveBall ("Arch_R" & Int(Rnd*4)+1), Vol(ActiveBall) * ArchSoundFactor
End Sub


Sub Arch1_hit()
	If Activeball.vely < -12 Then RandomSoundLeftArch
End Sub

Sub Arch2_hit()
	If Activeball.vely < -12 Then RandomSoundRightArch
End Sub

Sub Gate_hit()
	StopSound "Arch_R1"
	StopSound "Arch_R2"
	StopSound "Arch_R3"
	StopSound "Arch_R4"
	StopSound "Arch_L1"
	StopSound "Arch_L2"
	StopSound "Arch_L3"
	StopSound "Arch_L4"
End Sub


'/////////////////////////////  SAUCERS (KICKER HOLES)  ////////////////////////////

Sub SoundSaucerLock()
	PlaySoundAtLevelStatic ("Saucer_Enter_" & Int(Rnd*2)+1), SaucerLockSoundLevel, Activeball
End Sub

Sub SoundSaucerKick(scenario, saucer)
	Select Case scenario
		Case 0: PlaySoundAtLevelStatic SoundFX("Saucer_Empty", DOFContactors), SaucerKickSoundLevel, saucer
		Case 1: PlaySoundAtLevelStatic SoundFX("Saucer_Kick", DOFContactors), SaucerKickSoundLevel, saucer
	End Select
End Sub

'/////////////////////////////  BALL COLLISION SOUND  ////////////////////////////
Sub OnBallBallCollision(ball1, ball2, velocity)
	Dim snd
	Select Case Int(Rnd*7)+1
		Case 1 : snd = "Ball_Collide_1"
		Case 2 : snd = "Ball_Collide_2"
		Case 3 : snd = "Ball_Collide_3"
		Case 4 : snd = "Ball_Collide_4"
		Case 5 : snd = "Ball_Collide_5"
		Case 6 : snd = "Ball_Collide_6"
		Case 7 : snd = "Ball_Collide_7"
	End Select

	PlaySound (snd), 0, Csng(velocity) ^2 / 200 * BallWithBallCollisionSoundFactor * VolumeDial, AudioPan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub

'/////////////////////////////  GENERAL ILLUMINATION RELAYS  ////////////////////////////
Sub Sound_GI_Relay(toggle, obj)
	Select Case toggle
		Case 1
			PlaySoundAtLevelStatic ("Relay_GI_On"), 0.025*RelayGISoundLevel, obj
		Case 0
			PlaySoundAtLevelStatic ("Relay_GI_Off"), 0.025*RelayGISoundLevel, obj
	End Select
End Sub

Sub Sound_Flash_Relay(toggle, obj)
	Select Case toggle
		Case 1
			PlaySoundAtLevelStatic ("Relay_Flash_On"), 0.025*RelayFlashSoundLevel, obj			
		Case 0
			PlaySoundAtLevelStatic ("Relay_Flash_Off"), 0.025*RelayFlashSoundLevel, obj		
	End Select
End Sub

'/////////////////////////////  SPINNER SOUNDS  ////////////////////////////
SpinnerSoundLevel = 0.5                              					'volume level; range [0, 1]

Sub SoundSpinner(spinnerswitch)
	PlaySoundAtLevelStatic ("Spinner"), SpinnerSoundLevel, spinnerswitch
End Sub

'///////////////////////////  DROP TARGET HIT SOUNDS  ///////////////////////////

Sub RandomSoundDropTargetReset(obj)
	PlaySoundAtLevelStatic SoundFX("Drop_Target_Reset_" & Int(Rnd*6)+1,DOFContactors), 1, obj
End Sub

Sub SoundDropTargetDrop(obj)
	PlaySoundAtLevelStatic ("Drop_Target_Down_" & Int(Rnd*6)+1), 400, obj
End Sub


'/////////////////////////////////////////////////////////////////
'					End Mechanical Sounds
'/////////////////////////////////////////////////////////////////

'******************************************************
'**** RAMP ROLLING SFX
'******************************************************

'Ball tracking ramp SFX 1.0
'   Reqirements:
'          * Import A Sound File for each ball on the table for plastic ramps.  Call It RampLoop<Ball_Number> ex: RampLoop1, RampLoop2, ...
'          * Import a Sound File for each ball on the table for wire ramps. Call it WireLoop<Ball_Number> ex: WireLoop1, WireLoop2, ...
'          * Create a Timer called RampRoll, that is enabled, with a interval of 100
'          * Set RampBAlls and RampType variable to Total Number of Balls
'	Usage:
'          * Setup hit events and call WireRampOn True or WireRampOn False (True = Plastic ramp, False = Wire Ramp)
'          * To stop tracking ball
'                 * call WireRampOff
'                 * Otherwise, the ball will auto remove if it's below 30 vp units
'

Sub RampOff1_hit
	WireRampOff
End Sub

Sub RampOn1_Hit
	If Activeball.vely < 0 Then WireRampOn True
End Sub

Sub RampOn1_unHit
	If Activeball.vely > 0 Then WireRampOff
End Sub


Sub RampOn2_Hit
	If Activeball.vely < 0 Then WireRampOn True
End Sub

Sub RampOn2_unHit
	If Activeball.vely > 0 Then WireRampOff
End Sub

dim RampMinLoops : RampMinLoops = 4
dim rampAmpFactor

InitRampRolling

Sub InitRampRolling()
	Select Case RampRollAmpFactor
		Case 0
			rampAmpFactor = "_amp0"
		Case 1
			rampAmpFactor = "_amp2_5"
		Case 2
			rampAmpFactor = "_amp5"
		Case 3
			rampAmpFactor = "_amp7_5"
		Case 4
			rampAmpFactor = "_amp9"
		Case Else
			rampAmpFactor = "_amp0"
	End Select
End Sub

dim RampBalls(6,2)
RampBalls(0,0) = False
dim RampType(6)	

Sub WireRampOn(input)  : Waddball ActiveBall, input : RampRollUpdate: End Sub
Sub WireRampOff() : WRemoveBall ActiveBall.ID	: End Sub

Sub Waddball(input, RampInput)	'Add ball
	dim x : for x = 1 to uBound(RampBalls)	'Check, don't add balls twice
		if RampBalls(x, 1) = input.id then 
			if Not IsEmpty(RampBalls(x,1) ) then Exit Sub	'Frustating issue with BallId 0. Empty variable = 0
		End If
	Next

	For x = 1 to uBound(RampBalls)
		if IsEmpty(RampBalls(x, 1)) then 
			Set RampBalls(x, 0) = input
			RampBalls(x, 1)	= input.ID
			RampType(x) = RampInput
			RampBalls(x, 2)	= 0
			'exit For
			RampBalls(0,0) = True
			RampRoll.Enabled = 1	 'Turn on timer
			'RampRoll.Interval = RampRoll.Interval 'reset timer
			exit Sub
		End If
		if x = uBound(RampBalls) then 	'debug
			Debug.print "WireRampOn error, ball queue is full: " & vbnewline & _
			RampBalls(0, 0) & vbnewline & _
			Typename(RampBalls(1, 0)) & " ID:" & RampBalls(1, 1) & "type:" & RampType(1) & vbnewline & _
			Typename(RampBalls(2, 0)) & " ID:" & RampBalls(2, 1) & "type:" & RampType(2) & vbnewline & _
			Typename(RampBalls(3, 0)) & " ID:" & RampBalls(3, 1) & "type:" & RampType(3) & vbnewline & _
			Typename(RampBalls(4, 0)) & " ID:" & RampBalls(4, 1) & "type:" & RampType(4) & vbnewline & _
			Typename(RampBalls(5, 0)) & " ID:" & RampBalls(5, 1) & "type:" & RampType(5) & vbnewline & _
			" "
		End If
	next
End Sub

Sub WRemoveBall(ID)		'Remove ball
	dim ballcount : ballcount = 0
	dim x : for x = 1 to Ubound(RampBalls)
		if ID = RampBalls(x, 1) then 'remove ball
			Set RampBalls(x, 0) = Nothing
			RampBalls(x, 1) = Empty
			RampType(x) = Empty
			StopSound("RampLoop" & x & rampAmpFactor)
			StopSound("wireloop" & x & rampAmpFactor)
		end If
		'if RampBalls(x,1) = Not IsEmpty(Rampballs(x,1) then ballcount = ballcount + 1
		if not IsEmpty(Rampballs(x,1)) then ballcount = ballcount + 1
	next
	if BallCount = 0 then RampBalls(0,0) = False	'if no balls in queue, disable timer update
End Sub

Sub RampRoll_Timer():RampRollUpdate:End Sub

Sub RampRollUpdate()		'Timer update
	dim x : for x = 1 to uBound(RampBalls)
		if Not IsEmpty(RampBalls(x,1) ) then 
			if BallVel(RampBalls(x,0) ) > 1 then ' if ball is moving, play rolling sound
				If RampType(x) then 
					PlaySound("RampLoop" & x & rampAmpFactor), -1, VolPlayfieldRoll(RampBalls(x,0)) * 1.1 * VolumeDial, AudioPan(RampBalls(x,0)), 0, BallPitchV(RampBalls(x,0)), 1, 0, AudioFade(RampBalls(x,0))				
					StopSound("wireloop" & x & rampAmpFactor)
				Else
					StopSound("RampLoop" & x & rampAmpFactor)
					PlaySound("wireloop" & x & rampAmpFactor), -1, VolPlayfieldRoll(RampBalls(x,0)) * 1.1 * VolumeDial, AudioPan(RampBalls(x,0)), 0, BallPitch(RampBalls(x,0)), 1, 0, AudioFade(RampBalls(x,0))
				End If
				RampBalls(x, 2)	= RampBalls(x, 2) + 1
			Else
				StopSound("RampLoop" & x & rampAmpFactor)
				StopSound("wireloop" & x & rampAmpFactor)
			end if
			if RampBalls(x,0).Z < 30 and RampBalls(x, 2) > RampMinLoops then	'if ball is on the PF, remove  it
				StopSound("RampLoop" & x & rampAmpFactor)
				StopSound("wireloop" & x & rampAmpFactor)
				Wremoveball RampBalls(x,1)
			End If
		Else
			StopSound("RampLoop" & x & rampAmpFactor)
			StopSound("wireloop" & x & rampAmpFactor)
		end if
	next
	if not RampBalls(0,0) then RampRoll.enabled = 0

End Sub

Function BallPitch(ball) ' Calculates the pitch of the sound based on the ball speed
    BallPitch = pSlope(BallVel(ball), 1, -1000, 60, 10000)
End Function

Function BallPitchV(ball) ' Calculates the pitch of the sound based on the ball speed Variation
	BallPitchV = pSlope(BallVel(ball), 1, -4000, 60, 7000)
End Function

'******************************************************
'**** END RAMP ROLLING SFX
'******************************************************

'******************************
' Setup Backglass
'******************************

Dim xoff,yoff,zoff,xrot,zscale, xcen,ycen

Sub setup_backglass()
	xoff = -20
	yoff = 78
	zoff = 599
	xrot = -90

	center_digits()

	SetBackglass_Mid()
	SetBackglass_High()
end sub


'**********************************************
'*******	Set Up Backglass Flashers	*******
'**********************************************
' this is for lining up the backglass flashers on top of a backglass image

Sub SetBackglass_Mid()
	Dim obj

	For Each obj In BackglassMid
		obj.x = obj.x
		obj.height = - obj.y + 140
		obj.y = 80 'adjusts the distance from the backglass towards the user
	Next
End Sub


Sub SetBackglass_High()
	Dim obj

	For Each obj In BackglassHigh
		obj.x = obj.x
		obj.height = - obj.y + 140
		obj.y = 80 'adjusts the distance from the backglass towards the user
	Next
End Sub



' ***************************************************************************
'  BASIC FSS(SS TYPE1) 1-4 player,credit,bip,+extra 7 segment SETUP CODE
' ***************************************************************************

Sub center_digits()
	Dim ix, xx, yy, yfact, xfact, xobj

	zscale = 0.0000001

	xcen = 0 
	ycen = (780 /2 ) + (203 /2)

	for ix = 0 to 31
		For Each xobj In Digits(ix)

			xx = xobj.x  
				
			xobj.x = (xoff - xcen) + xx
			yy = xobj.y ' get the yoffset before it is changed
			xobj.y = yoff - 10

			If (yy < 0.) then
				yy = yy * -1
			end if

			xobj.height = (zoff - ycen) + yy - (yy * (zscale))
			xobj.rotx = xrot
		Next
	Next
end sub


Dim Digits(32)
Digits(0) = Array(LED1x0,LED1x1,LED1x2,LED1x3,LED1x4,LED1x5,LED1x6,LED1x7)
Digits(1) = Array(LED2x0,LED2x1,LED2x2,LED2x3,LED2x4,LED2x5,LED2x6)
Digits(2) = Array(LED3x0,LED3x1,LED3x2,LED3x3,LED3x4,LED3x5,LED3x6)
Digits(3) = Array(LED4x0,LED4x1,LED4x2,LED4x3,LED4x4,LED4x5,LED4x6,LED4x7)
Digits(4) = Array(LED5x0,LED5x1,LED5x2,LED5x3,LED5x4,LED5x5,LED5x6)
Digits(5) = Array(LED6x0,LED6x1,LED6x2,LED6x3,LED6x4,LED6x5,LED6x6)
Digits(6) = Array(LED7x0,LED7x1,LED7x2,LED7x3,LED7x4,LED7x5,LED7x6)

Digits(7) = Array(LED8x0,LED8x1,LED8x2,LED8x3,LED8x4,LED8x5,LED8x6,LED8x7)
Digits(8) = Array(LED9x0,LED9x1,LED9x2,LED9x3,LED9x4,LED9x5,LED9x6)
Digits(9) = Array(LED10x0,LED10x1,LED10x2,LED10x3,LED10x4,LED10x5,LED10x6)
Digits(10) = Array(LED11x0,LED11x1,LED11x2,LED11x3,LED11x4,LED11x5,LED11x6,LED11x7)
Digits(11) = Array(LED12x0,LED12x1,LED12x2,LED12x3,LED12x4,LED12x5,LED12x6)
Digits(12) = Array(LED13x0,LED13x1,LED13x2,LED13x3,LED13x4,LED13x5,LED13x6)
Digits(13) = Array(LED14x0,LED14x1,LED14x2,LED14x3,LED14x4,LED14x5,LED14x6)

Digits(14) = Array(LED1x000,LED1x001,LED1x002,LED1x003,LED1x004,LED1x005,LED1x006,LED1x8)
Digits(15) = Array(LED1x100,LED1x101,LED1x102,LED1x103,LED1x104,LED1x105,LED1x106)
Digits(16) = Array(LED1x200,LED1x201,LED1x202,LED1x203,LED1x204,LED1x205,LED1x206)
Digits(17) = Array(LED1x300,LED1x301,LED1x302,LED1x303,LED1x304,LED1x305,LED1x306,LED1x9)
Digits(18) = Array(LED1x400,LED1x401,LED1x402,LED1x403,LED1x404,LED1x405,LED1x406)
Digits(19) = Array(LED1x500,LED1x501,LED1x502,LED1x503,LED1x504,LED1x505,LED1x506)
Digits(20) = Array(LED1x600,LED1x601,LED1x602,LED1x603,LED1x604,LED1x605,LED1x606)

Digits(21) = Array(LED2x000,LED2x001,LED2x002,LED2x003,LED2x004,LED2x005,LED2x006,LED2x7)
Digits(22) = Array(LED2x100,LED2x101,LED2x102,LED2x103,LED2x104,LED2x105,LED2x106)
Digits(23) = Array(LED2x200,LED2x201,LED2x202,LED2x203,LED2x204,LED2x205,LED2x206)
Digits(24) = Array(LED2x300,LED2x301,LED2x302,LED2x303,LED2x304,LED2x305,LED2x306,LED2x8)
Digits(25) = Array(LED2x400,LED2x401,LED2x402,LED2x403,LED2x404,LED2x405,LED2x406)
Digits(26) = Array(LED2x500,LED2x501,LED2x502,LED2x503,LED2x504,LED2x505,LED2x506)
Digits(27) = Array(LED2x600,LED2x601,LED2x602,LED2x603,LED2x604,LED2x605,LED2x606)


Digits(28) = Array(LEDax300,LEDax301,LEDax302,LEDax303,LEDax304,LEDax305,LEDax306)
Digits(29) = Array(LEDbx400,LEDbx401,LEDbx402,LEDbx403,LEDbx404,LEDbx405,LEDbx406)
Digits(30) = Array(LEDcx500,LEDcx501,LEDcx502,LEDcx503,LEDcx504,LEDcx505,LEDcx506)
Digits(31) = Array(LEDdx600,LEDdx601,LEDdx602,LEDdx603,LEDdx604,LEDdx605,LEDdx606)


dim DisplayColor
DisplayColor =  RGB(255,40,1)

Sub DisplayTimer
	Dim ChgLED, ii, jj, num, chg, stat, obj, b, x
	ChgLED=Controller.ChangedLEDs(&Hffffffff, &Hffffffff)
	If Not IsEmpty(ChgLED)Then
		For ii=0 To UBound(chgLED)
			num=chgLED(ii, 0) : chg=chgLED(ii, 1) : stat=chgLED(ii, 2)
			if (num < 32) then
				For Each obj In Digits(num)
					If chg And 1 Then FadeDisplay obj, stat And 1
					chg=chg\2 : stat=stat\2
				Next
			end if
		Next
	End If
End Sub


Sub FadeDisplay(object, onoff)
	If OnOff = 1 Then
		object.color = DisplayColor
		Object.Opacity = 10
	Else
		Object.Color = RGB(7,7,7)
		Object.Opacity = 10
	End If
End Sub


Sub InitDigits()
	dim tmp, x, obj
	for x = 0 to uBound(Digits)
		if IsArray(Digits(x) ) then
			For each obj in Digits(x)
				obj.height = obj.height + 18
				FadeDisplay obj, 0
			next
		end If
	Next
End Sub

InitDigits



Dim Starfighter: Starfighter = 10

'VR Stuff Below.. ****************************************************************************************************

Dim skymove:skymove = 0.02/8			'Sky
Dim meteormove1:meteormove1 = 0.06   	'For VR Meteors
Dim meteormove2:meteormove2 = 0.08

Dim MoveShip: MoveShip = 0.2			'Star Fighter
Dim MoveShip2: MoveShip2 = 0.25
Dim ShipCount:ShipCount = 0

VR_Space_FlyingShip.size_x = Starfighter
VR_Space_FlyingShip.size_y = Starfighter
VR_Space_FlyingShip.size_z = Starfighter


Dim starmove1:starmove1=22				'Shooting Stars
Dim starmove2:starmove2=-24

Dim ShipSpeed: ShipSpeed = 4			'Moon Lander
Dim WobbleSpeed:WobbleSpeed = 0.04
Dim WobbleSpeed2:WobbleSpeed2 = 0.02
Dim ShipControl:ShipControl = 0
Dim VRFireCounter:VRFireCounter = 1

Dim UFOLight:UFOLight = 400				'UFO

Dim AlienCount:AlienCount = 0			'Alien
Dim AlienCount2:AlienCount2 = 0
Dim eyemove:eyemove = 2

Sub VR_Space_Timer_Timer()
	'##### Sky
	VR_Space_Sky.ObjRotZ=VR_Space_Sky.ObjRotZ + skymove

	'##### Rocks
	VR_Space_Rock1.ObjRotZ=VR_Space_Rock1.ObjRotZ+meteormove1
	VR_Space_Rock1.ObjRotX=VR_Space_Rock1.ObjRotX+meteormove2

	VR_Space_Rock2.ObjRotZ=VR_Space_Rock2.ObjRotZ+meteormove1
	VR_Space_Rock2.ObjRotX=VR_Space_Rock2.ObjRotX+meteormove2

	VR_Space_Rock4.ObjRotZ=VR_Space_Rock4.ObjRotZ+meteormove2
	VR_Space_Rock4.ObjRotX=VR_Space_Rock4.ObjRotX+meteormove1

	VR_Space_Rock7.ObjRotZ=VR_Space_Rock7.ObjRotZ+meteormove2
	VR_Space_Rock7.ObjRotX=VR_Space_Rock7.ObjRotX+meteormove1

	'##### Space Station
	VR_Space_SpaceStation.ObjRotZ=VR_Space_SpaceStation.ObjRotZ+meteormove1

	'##### Star Fighter
	VR_Space_FlyingShip.ObjRotZ=VR_Space_FlyingShip.ObjRotZ - 0.08*2

	VR_Space_FlyingShip.z = VR_Space_FlyingShip.z + MoveShip*Starfighter/10
	VR_Space_FlyingShip.TransX = VR_Space_FlyingShip.TransX + MoveShip2*Starfighter/10

	if VR_Space_FlyingShip.TransX =< -2500*Starfighter/10 then Moveship2 = Moveship2 * -1:VR_Space_FlyingShip.TransX = -2500*Starfighter/10
	if VR_Space_FlyingShip.TransX => -1050*Starfighter/10 then Moveship2 = Moveship2 * -1:VR_Space_FlyingShip.TransX = -1050*Starfighter/10
	
	if VR_Space_FlyingShip.z => 2200 then Moveship = Moveship * -1:VR_Space_FlyingShip.z = 2200
	if VR_Space_FlyingShip.z =< 300 then Moveship = Moveship * -1:VR_Space_FlyingShip.z = 300

	ShipCount = ShipCount + 1 

	if ShipCount = 50 then 
		VR_Space_FlyingShip.image = "VR_Space_SF_Fighter2"
	elseif ShipCount = 100 then 
		VR_Space_FlyingShip.image = "VR_Space_SF_Fighter3"
	elseif ShipCount >= 150 Then
		VR_Space_FlyingShip.image = "VR_Space_SF_Fighter1"
		ShipCount = 0
	end if

	'##### Moon
	VR_Space_Moon.ObjRotZ=VR_Space_Moon.ObjRotZ+meteormove1/4

	'##### Falling Stars
	VR_Space_FallingStar1.ObjRotZ=VR_Space_FallingStar1.ObjRotZ+meteormove2
	VR_Space_FallingStar1.ObjRotX=VR_Space_FallingStar1.ObjRotX+meteormove2

	VR_Space_FallingStar2.ObjRotZ=VR_Space_FallingStar2.ObjRotZ+meteormove2
	VR_Space_FallingStar2.ObjRotX=VR_Space_FallingStar2.ObjRotX+meteormove2

	VR_Space_FallingStar1.Y=VR_Space_FallingStar1.Y + starmove1
	VR_Space_FallingStar2.Y=VR_Space_FallingStar2.Y + starmove2

	If VR_Space_FallingStar1.Y>=50000 then Randomize (21): VR_Space_FallingStar1.Y = -42000: VR_Space_FallingStar1.X = 15000 + rnd(1)*-25000 : VR_Space_FallingStar1.Size_x = 1300 * rnd(1) +320 : VR_Space_FallingStar1.Size_y = 1300 * rnd(1) +320: VR_Space_FallingStar1.Size_z = 1300 * rnd(1) +550' Randomize X position, x,y,z size here
	If VR_Space_FallingStar2.Y<=-40000 then Randomize (5): VR_Space_FallingStar2.Y = 50000: VR_Space_FallingStar2.X = 15000 + rnd(1)*-25000 : VR_Space_FallingStar2.Size_x = 1300 * rnd(1) +320 : VR_Space_FallingStar2.Size_y = 1300 * rnd(1) +320: VR_Space_FallingStar2.Size_z = 1300 * rnd(1) +550' Randomize X position, x,y,z size here

	'##### Moon Lander
	If ShipControl >= 2000 Then
		VR_Space_Fire.visible = true

		VR_Space_Fire.Image = "VR_Space_Fire_" & VRFireCounter
		VRFireCounter = VRFireCounter + 1

		If VRFireCounter > 59 Then
			VRFireCounter = 0
		end If

		VR_Space_Moonbase.z = VR_Space_Moonbase.z + ShipSpeed
		VR_Space_Fire.z = VR_Space_Fire.z + ShipSpeed

		if VR_Space_Moonbase.z  = 14496 Then
			ShipSpeed = -4
		end if


		if VR_Space_Moonbase.z  <= -788 Then
			VR_Space_Moonbase.z = -784
			ShipSpeed = 4
			ShipControl = 0
		Elseif VR_Space_Moonbase.z  > 0 Then
			VR_Space_Moonbase.Roty = VR_Space_Moonbase.Roty + WobbleSpeed 
			VR_Space_Moonbase.Rotz = VR_Space_Moonbase.Rotz + WobbleSpeed2
			VR_Space_Moonbase.Rotx = VR_Space_Moonbase.Rotx + WobbleSpeed

			if VR_Space_Moonbase.Roty > -30 then 
				WobbleSpeed = -0.04 
				WobbleSpeed2 = -0.02 
			end If

			if VR_Space_Moonbase.Roty < -38 then 
				WobbleSpeed = 0.04 
				WobbleSpeed2 = 0.02 
			end If
		Else
			VR_Space_Moonbase.Roty = -34 ' bring ship back flat
			VR_Space_Moonbase.Rotz = 0
			VR_Space_Moonbase.Rotx = 92
		end if
	Else
		VR_Space_Fire.visible = false
		ShipControl = ShipControl + 1
	End If

	'#####   UFO
	UFOLight = UFOLight + 1

	if UFOLight = 400 Then
		VR_Space_RedUFO.visible = true
		VR_Space_UFOMiddle.disablelighting = 1
	Elseif UFOLight >= 800 then
		UFOLight = 0
		VR_Space_RedUFO.visible = false
		VR_Space_UFOMiddle.disablelighting = 0
	end if

	'#####  Alien
	If AlienCount = 0 Then
		VR_Space_Alien.size_x = 500
		VR_Space_Alien.size_y = 500
		VR_Space_Alien.size_z = 500
		VR_Space_Alien.transx = 7500
		VR_Space_Alien.transy = 3710
		VR_Space_Alien.transz = 22200
		VR_Space_Alien.rotz = 0
		VR_Space_Alien.material = "_VR_noXtraShadingBlk"
		AlienCount = 1
	End If

	If AlienCount = 41 Then
		VR_Space_Alienshadow.z = -790:
		VR_Space_Alienshadow1.z = -790:
		VR_Space_Alienshadow2.z = -790:
		VR_Space_Alien.size_x = 600
		VR_Space_Alien.size_y = 600
		VR_Space_Alien.size_z = 600
		VR_Space_Alien.transx = 0
		VR_Space_Alien.transy = 0
		VR_Space_Alien.transz = 0
		VR_Space_Alien.rotz = -2
		VR_Space_Alien.material = "_VR_Spaceship"
		VR_Space_Lefteye.Z = 1238: 
		VR_Space_Righteye.z = 1186
		AlienCount = 42
	End If

	If AlienCount => 41 Then
		AlienCount2 = AlienCount2 + 1

		If AlienCount2 >= 10 Then
			VR_Space_LeftEye.ObjRotZ=VR_Space_Lefteye.ObjRotZ+eyemove
			VR_Space_RightEye.ObjRotZ=VR_Space_Righteye.ObjRotZ+eyemove

			if VR_Space_Lefteye.ObjRotz >= 30 then eyemove = -2
			if VR_Space_Lefteye.ObjRotz <= -10 then eyemove = 2
			
			AlienCount2 = 0
		End If
	End If

end sub


Dim aa
if VRRoom = 1 then 
	for each aa in VR_Room_Space: aa.visible = 1 : next
	for each aa in VRMinimal: aa.visible = 0 : next
	for each aa in VRCabinet: aa.visible = 1 : next
	VR_Space_Timer.enabled = True		
Elseif VRRoom = 2 Then
	for each aa in VR_Room_Space: aa.visible = 0 : next
	for each aa in VRMinimal: aa.visible = 1 : next
	for each aa in VRCabinet: aa.visible = 1 : next
	VR_Space_Timer.enabled = False
Else
	for each aa in VR_Room_Space: aa.visible = 0 : next
	for each aa in VRMinimal: aa.visible = 0 : next
	If cabmode = 0 Then 
		for each aa in VRCabinet: aa.visible = 1 : next
	Else
		for each aa in VRCabinet: aa.visible = 0 : next
	End If
	VR_Space_Timer.enabled = False		
End If		
