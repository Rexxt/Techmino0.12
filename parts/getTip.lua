local L
if setting.lang==1 then
	L={
		"不是动画,真的在加载!",
		"大满贯10连击消四全清!",
		"<方块研究所>有一个Nspire-CX版本!",
		"B2B2B???",
		"B2B2B2B存在吗?",
		"MEGACMB!",
		"ALLSPIN!",
		"O型回旋三清!",
		"Miya:喵!",
		"2+2=Miya",
		"225238922  哔哩哔哩 干杯~",
		"适度游戏益脑,沉迷游戏伤身,合理安排时间,享受健康生活",
		"合群了就会消失,但是消失不代表没有意义",
		"学会使用两个旋转键,三个更好",
		"更小的DAS和ARR拥有更高的操作上限(如果你还能控制得了的话)",
		"注意到\"旋转\"到底对方块做了些什么吗?",
		"20G本质是一套全新的游戏规则",
		"不要在上课时玩游戏!",
		"本游戏难度上限很高,做好心理准备",
		"本游戏可不是休闲游戏",
		"调到特殊的日期也不会发生什么的",
		"3.1415926535897932384",
		"2.7182818284590452353",
		"Let-The-Bass-Kick!",
		"使用love2d引擎制作",
		"有疑问?先看设置有没有你想要的",
		"有建议的话可以把信息反馈给作者~",
		"不要按F8",
		"秘密数字:626",
		"CLASSIC SEXY RUSSIAN BLOCKS",
		"戴上耳机以获得最佳体验",
		"少女祈祷中",
		"LrL,RlR  LLr,RRl  RRR/LLL  F!!",--ZSLJTTI
		"(第一次才准)今日幸运数字:"..math.random(100,626),
	}
elseif setting.lang==2 then
	L={
		"不是动画,真的在加载!",
		"大满贯10连击消四全清!",
		"<方块研究所>有一个Nspire-CX版本!",
		"B2B2B???",
		"B2B2B2B存在吗?",
		"MEGACMB!",
		"ALLSPIN!",
		"O spin triple!",
		"Miya:喵!",
		"2*2=Miya",
		"225238922  哔哩哔哩 干杯~",
		"适度游戏益脑,沉迷游戏伤身,合理安排时间,享受健康生活",
		"合群了就会消失,但是消失不代表没有意义",
		"学会使用两个旋转键,三个更好",
		"更小的DAS和ARR拥有更高的操作上限(如果你还能控制得了的话)",
		"注意到\"旋转\"到底对方块做了些什么吗?",
		"20G本质是一套全新的游戏规则",
		"不要在上课时玩游戏!",
		"本游戏难度上限很高,做好心理准备",
		"本游戏可不是休闲游戏",
		"调到特殊的日期也不会发生什么的",
		"3.1415926535897932384",
		"2.7182818284590452353",
		"Let-The-Bass-Kick!",
		"使用love2d引擎制作",
		"有疑问?先看设置有没有你想要的",
		"有建议的话可以把信息反馈给作者~",
		"不要按F8",
		"秘密数字:626",
		"CLASSIC SEXY RUSSIAN BLOCKS",
		"戴上耳机以获得最佳体验",
		"少女祈祷中",
		"LrL,RlR  LLr,RRl  RRR/LLL  F!!",--ZSLJTTI
		"(第一次才准)今日幸运数字:"..math.random(100,626),
	}
elseif setting.lang==3 then
	L={
		"Not animation,real loading!",
		"Back to Back 10 combo Techrash PC!",
		"Techmino has a Nspire-CX edition!",
		"B2B2B???",
		"Is B2B2B2B possible?",
		"MEGACMB!",
		"ALLSPIN!",
		"O spin triple!",
		"Miya:Nya!",
		"2^2=Miya",
		"225238922  Bilibili cheers!",
		"Playing too much = taking drugs",
		"Disappearing doesn't mean useless",
		"Try to use two rotate button,three better",
		"Small DAS&ARR can make you faster,if you can control block correctly",
		"Have you noticed what does \"rotating\" do to block?",
		"20G actually is a brand new game rule",
		"Do not play game in class!",
		"This game can be very hard,be mentally perpared",
		"This in not a casual game",
		"Nothing will happen when some special day come",
		"3.1415926535897932384",
		"2.7182818284590452353",
		"Let-The-Bass-Kick!",
		"Powered by love2d",
		"Find out what's in the setting!",
		"Any suggestions to author!",
		"DO NOT PRESS F8",
		"Secret num:626",
		"Techmino=Technique+Tetromino",
		"CLASSIC SEXY RUSSIAN BLOCKS",
		"Headphones for better experience",
		"少女祈禱中",
		"LrL,RlR  LLr,RRl  RRR/LLL  F!!",--ZSLJTTI
	}
end
return L[math.random(#L)]