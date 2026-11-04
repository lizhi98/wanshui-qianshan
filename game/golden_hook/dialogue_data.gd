extends RefCounted
## Original chapter dialogue. Replace WAV files by these stable line IDs.
const GROUPS={
  "intro": [
    {
      "id": "intro_01",
      "speaker": "旁白",
      "text": "一九三五年秋，另一支红军队伍进入了茫茫草地。",
      "mood": "叙事，平缓"
    },
    {
      "id": "intro_02",
      "speaker": "旁白",
      "text": "三名掉队的年轻病号，由一位炊事班老班长照顾。你是其中的小梁。",
      "mood": "介绍人物"
    },
    {
      "id": "intro_03",
      "speaker": "老班长",
      "text": "醒了？先坐稳，别急着起身。夜里的雨已经停了。",
      "mood": "温和"
    },
    {
      "id": "intro_04",
      "speaker": "小梁",
      "text": "班长，我们离队伍又远了吗？",
      "mood": "虚弱，担心"
    },
    {
      "id": "intro_05",
      "speaker": "老班长",
      "text": "能走一段，就离他们近一段。先把身子撑住。",
      "mood": "平稳，鼓励"
    },
    {
      "id": "intro_06",
      "speaker": "老班长",
      "text": "帮我看看粮袋，再问问他们的精神。草甸上还有一点可用的菜。",
      "mood": "布置任务"
    },
    {
      "id": "intro_07",
      "speaker": "老班长",
      "text": "沿有脚印的地方走。水颜色深的地方，千万别踩。",
      "mood": "郑重提醒"
    }
  ],
  "bag_a": [
    {
      "id": "bag_a_01",
      "speaker": "小梁",
      "text": "袋底只剩一层细细的粮粉，捏起来还带着潮气。",
      "mood": "观察"
    },
    {
      "id": "bag_a_02",
      "speaker": "老班长",
      "text": "把袋口扎好。再少，也得留住。",
      "mood": "压住担忧"
    }
  ],
  "bag_b": [
    {
      "id": "bag_b_01",
      "speaker": "小梁",
      "text": "这个袋子也空了。补过的地方，连粮屑都没有。",
      "mood": "低声"
    },
    {
      "id": "bag_b_02",
      "speaker": "老班长",
      "text": "我再想想办法。你先看看战友。",
      "mood": "克制"
    }
  ],
  "comrade_a": [
    {
      "id": "comrade_a_01",
      "speaker": "小石",
      "text": "我听见外头有人走路，以为是队伍回来了。",
      "mood": "疲倦"
    },
    {
      "id": "comrade_a_02",
      "speaker": "小梁",
      "text": "是班长在拾干柴。等歇过这阵，我们也能走。",
      "mood": "安慰"
    }
  ],
  "comrade_b": [
    {
      "id": "comrade_b_01",
      "speaker": "阿青",
      "text": "我还能拿自己的东西。别都让班长背着。",
      "mood": "勉强振作"
    },
    {
      "id": "comrade_b_02",
      "speaker": "小梁",
      "text": "先把水喝了。东西我帮你收。",
      "mood": "照顾"
    }
  ],
  "ration": [
    {
      "id": "ration_01",
      "speaker": "小梁",
      "text": "三个人的口粮，只铺得住碗底。班长把自己的那份藏在哪里？",
      "mood": "疑问"
    }
  ],
  "supplies_done": [
    {
      "id": "supplies_done_01",
      "speaker": "小梁",
      "text": "两只袋子都见了底。能用的菜，我也带回来了。",
      "mood": "担忧"
    },
    {
      "id": "supplies_done_02",
      "speaker": "老班长",
      "text": "够这一顿。可后面的路……",
      "mood": "停顿"
    },
    {
      "id": "supplies_done_03",
      "speaker": "旁白",
      "text": "水边忽然响了一下。灰暗的水面上，一尾小鱼翻出细碎的光。",
      "mood": "希望出现"
    },
    {
      "id": "supplies_done_04",
      "speaker": "老班长",
      "text": "有鱼。只要能做出一枚钩子，我们就还有办法。",
      "mood": "轻微振奋"
    },
    {
      "id": "supplies_done_05",
      "speaker": "老班长",
      "text": "旧衣袋里有针。找一段线，再挑根结实的细枝。",
      "mood": "行动起来"
    }
  ],
  "craft_done": [
    {
      "id": "craft_done_01",
      "speaker": "老班长",
      "text": "针身得弯牢，线头得拴紧。来，帮我把这一段扶稳。",
      "mood": "细致"
    },
    {
      "id": "craft_done_02",
      "speaker": "小梁",
      "text": "这么小的一枚钩子，真能钓到鱼吗？",
      "mood": "好奇"
    },
    {
      "id": "craft_done_03",
      "speaker": "老班长",
      "text": "别看它小。先去试一试，水里总有活路。",
      "mood": "温和，坚定"
    }
  ],
  "demo": [
    {
      "id": "demo_01",
      "speaker": "老班长",
      "text": "竿别举得太直。蓄一点力，把浮标送到水面中间。",
      "mood": "示范"
    },
    {
      "id": "demo_02",
      "speaker": "老班长",
      "text": "轻轻晃，是鱼在试探。等它明显沉下去，再提。",
      "mood": "留出停顿"
    },
    {
      "id": "demo_03",
      "speaker": "老班长",
      "text": "挂住以后也别猛拉。线紧就松一点，松了再收。",
      "mood": "耐心"
    },
    {
      "id": "demo_04",
      "speaker": "小梁",
      "text": "我来试试。您在旁边歇一会儿。",
      "mood": "认真"
    }
  ],
  "first_fish": [
    {
      "id": "first_fish_01",
      "speaker": "小梁",
      "text": "真钓上来了！比拇指还长一点。",
      "mood": "克制的欣喜"
    },
    {
      "id": "first_fish_02",
      "speaker": "老班长",
      "text": "收进篓里，别让它掉回去。再来一条，就能煮汤了。",
      "mood": "温暖"
    }
  ],
  "two_fish": [
    {
      "id": "two_fish_01",
      "speaker": "小梁",
      "text": "两条都在篓里。我们回去，把汤煮上。",
      "mood": "轻微振奋"
    },
    {
      "id": "two_fish_02",
      "speaker": "老班长",
      "text": "慢点走，路滑。我把火塘收拾好。",
      "mood": "照顾"
    }
  ],
  "soup_ready": [
    {
      "id": "soup_ready_01",
      "speaker": "老班长",
      "text": "先盛给他们。捧稳，碗沿还是烫的。",
      "mood": "亲切"
    },
    {
      "id": "soup_ready_02",
      "speaker": "小梁",
      "text": "班长，您的碗呢？",
      "mood": "询问"
    },
    {
      "id": "soup_ready_03",
      "speaker": "老班长",
      "text": "我先前吃过了。你也趁热喝，别光顾着看我。",
      "mood": "平常，稍避开目光"
    }
  ],
  "serve_a": [
    {
      "id": "serve_a_01",
      "speaker": "小石",
      "text": "我好多了。等会儿我来收铺盖。",
      "mood": "恢复一点精神"
    },
    {
      "id": "serve_a_02",
      "speaker": "小梁",
      "text": "先喝完。今天我们一起走。",
      "mood": "温暖"
    }
  ],
  "serve_b": [
    {
      "id": "serve_b_01",
      "speaker": "阿青",
      "text": "这么暖的东西，好像很久没喝到了。",
      "mood": "轻声"
    },
    {
      "id": "serve_b_02",
      "speaker": "阿青",
      "text": "班长又去哪儿了？他的脚步听起来很轻。",
      "mood": "留意"
    }
  ],
  "after_soup": [
    {
      "id": "after_soup_01",
      "speaker": "小梁",
      "text": "火塘旁少了一只碗。他刚才往那片草丛去了。",
      "mood": "疑惑"
    },
    {
      "id": "after_soup_02",
      "speaker": "旁白",
      "text": "绕过低矮的石头，你听见一声被忍住的咳嗽。",
      "mood": "安静"
    }
  ],
  "secret": [
    {
      "id": "secret_01",
      "speaker": "小梁",
      "text": "班长……这碗里，怎么只有草根和鱼骨？",
      "mood": "震动，压低声音"
    },
    {
      "id": "secret_02",
      "speaker": "老班长",
      "text": "你怎么走过来了。夜里凉，回火边坐。",
      "mood": "短暂停顿，掩饰"
    },
    {
      "id": "secret_03",
      "speaker": "小梁",
      "text": "您说吃过了。原来吃的是这些。",
      "mood": "克制"
    },
    {
      "id": "secret_04",
      "speaker": "老班长",
      "text": "你们还病着，一点鱼肉，能多添一点气力。",
      "mood": "平缓"
    },
    {
      "id": "secret_05",
      "speaker": "小梁",
      "text": "可您也要走路，也会饿。",
      "mood": "低声，坚持"
    },
    {
      "id": "secret_06",
      "speaker": "老班长",
      "text": "我知道。可带你们走到有炊烟的地方，是我答应下来的事。",
      "mood": "坚定，轻声"
    },
    {
      "id": "secret_07",
      "speaker": "小梁",
      "text": "明天让我多做一点。您教过的，我记住了。",
      "mood": "理解"
    },
    {
      "id": "secret_08",
      "speaker": "老班长",
      "text": "好。咱们一道想办法，一道往前走。",
      "mood": "温和"
    }
  ],
  "march": [
    {
      "id": "march_01",
      "speaker": "旁白",
      "text": "此后的几天，火塘一次次熄灭，又在新的草甸上亮起。",
      "mood": "时间推进"
    },
    {
      "id": "march_02",
      "speaker": "小石",
      "text": "我来背这只锅。班长，您把手腾出来。",
      "mood": "照顾"
    },
    {
      "id": "march_03",
      "speaker": "老班长",
      "text": "好。看着脚下，跟小梁走实地。",
      "mood": "渐弱"
    },
    {
      "id": "march_04",
      "speaker": "旁白",
      "text": "队伍的脚步渐渐有了力气。老班长的背，却一天比一天低。",
      "mood": "克制"
    },
    {
      "id": "march_05",
      "speaker": "阿青",
      "text": "前面的山线清楚了。出了这段水洼，路会好走些。",
      "mood": "盼望"
    },
    {
      "id": "march_06",
      "speaker": "老班长",
      "text": "你们在避风处等一等。我去水边看看。",
      "mood": "掩住疲惫"
    }
  ],
  "search": [
    {
      "id": "search_01",
      "speaker": "小石",
      "text": "他出去好一会儿了。我不放心。",
      "mood": "担心"
    },
    {
      "id": "search_02",
      "speaker": "小梁",
      "text": "沿着水塘找。我走前面，你们跟紧。",
      "mood": "主动"
    }
  ],
  "found_elder": [
    {
      "id": "found_elder_01",
      "speaker": "小梁",
      "text": "班长！听得见我们吗？",
      "mood": "急切，控制音量"
    },
    {
      "id": "found_elder_02",
      "speaker": "阿青",
      "text": "把他扶稳，别让风直吹着。我留在这儿。",
      "mood": "镇定"
    },
    {
      "id": "found_elder_03",
      "speaker": "小石",
      "text": "锅和火种都在。我来生火。",
      "mood": "迅速"
    },
    {
      "id": "found_elder_04",
      "speaker": "小梁",
      "text": "我去钓一条鱼。竿给我，我记得怎么用。",
      "mood": "坚定"
    },
    {
      "id": "found_elder_05",
      "speaker": "旁白",
      "text": "这一次，你拿起鱼竿，是为了那个一直照顾你的人。",
      "mood": "克制"
    }
  ],
  "last_fish": [
    {
      "id": "last_fish_01",
      "speaker": "小梁",
      "text": "鱼在这里。把水烧开，我来端汤。",
      "mood": "急促但清楚"
    },
    {
      "id": "last_fish_02",
      "speaker": "小石",
      "text": "火已经起来了。我们一起做。",
      "mood": "低声"
    }
  ],
  "last_soup": [
    {
      "id": "last_soup_01",
      "speaker": "小梁",
      "text": "班长，汤好了。我扶着碗，您慢慢喝。",
      "mood": "缓慢，靠近"
    },
    {
      "id": "last_soup_02",
      "speaker": "老班长",
      "text": "小梁……你们，都在。",
      "mood": "气息很轻"
    },
    {
      "id": "last_soup_03",
      "speaker": "小梁",
      "text": "都在。我们陪着您。",
      "mood": "轻声"
    },
    {
      "id": "last_soup_04",
      "speaker": "老班长",
      "text": "前面的路，接着走。别把脚步停在我这里。",
      "mood": "微弱而平静"
    },
    {
      "id": "last_soup_05",
      "speaker": "老班长",
      "text": "把队伍跟上。你们都要走出去。",
      "mood": "最后嘱托，长停顿"
    }
  ],
  "silence": [
    {
      "id": "silence_01",
      "speaker": "旁白",
      "text": "风掠过水面。那只一直替别人端碗的手，慢慢安静下来。",
      "mood": "压低，句后留白"
    }
  ],
  "keepsake": [
    {
      "id": "keepsake_01",
      "speaker": "小梁",
      "text": "是那枚针做的鱼钩。钩尖已经磨钝，锈色留在弯处。",
      "mood": "观察，悲伤"
    },
    {
      "id": "keepsake_02",
      "speaker": "阿青",
      "text": "把它收好。以后走到哪里，都带着。",
      "mood": "低声"
    },
    {
      "id": "keepsake_03",
      "speaker": "小梁",
      "text": "我会带着。也会把这一段路，讲给后来的人听。",
      "mood": "坚定"
    }
  ],
  "onward": [
    {
      "id": "onward_01",
      "speaker": "小石",
      "text": "我扶着你。咱们往前走。",
      "mood": "温和"
    },
    {
      "id": "onward_02",
      "speaker": "小梁",
      "text": "一起走。",
      "mood": "坚定"
    },
    {
      "id": "onward_03",
      "speaker": "旁白",
      "text": "一枚鱼钩，留住了一双手的温度，也留住了继续前行的力量。",
      "mood": "庄重"
    }
  ],
  "archive": [
    {
      "id": "archive_01",
      "speaker": "旁白",
      "text": "本章依据杨旭的文学作品金色的鱼钩，创作原创互动与对白。",
      "mood": "说明"
    },
    {
      "id": "archive_02",
      "speaker": "旁白",
      "text": "文学中的老班长，与现实中的老红军王玉清，不能完全等同。",
      "mood": "清晰"
    },
    {
      "id": "archive_03",
      "speaker": "旁白",
      "text": "王玉清一九三五年十一月参加红军。他在一九三六年的草地行军中，用缝衣针做钩，与战友分享鱼汤。",
      "mood": "史料"
    },
    {
      "id": "archive_04",
      "speaker": "旁白",
      "text": "他活着走出了草地，于二〇二三年逝世。",
      "mood": "郑重"
    },
    {
      "id": "archive_05",
      "speaker": "旁白",
      "text": "一九三五年中央红军抵达陕北，与一九三六年三大主力胜利会师，是两个不同的历史节点。",
      "mood": "说明"
    }
  ]
}

# Registry remains complete; the active edit is independent of stable audio IDs.
const RETIRED={
  "intro_02": "以角色名称和实际营地人物建立关系，删除第二次介绍",
  "intro_06": "任务目标已经显示，避免重复布置",
  "intro_07": "以实际泥沼反馈、路径与短提示代替开场说明",
  "bag_a_01": "以空袋的实物近景代替重复读出内容",
  "bag_b_01": "第二个空袋由观察动作和袋底表现",
  "comrade_a_02": "保留小石本人的疲倦描述，删除回应的重复解释",
  "comrade_b_02": "让递水和携带动作承担照顾关系",
  "supplies_done_01": "已完成的收集不再逐项复述",
  "supplies_done_03": "鱼跃和实际水花代替旁白解释鱼跃",
  "supplies_done_05": "针、线、枝的收集目标已在界面和道具中呈现",
  "craft_done_01": "同一枚针的弯曲、系线与安装动作已实际发生",
  "two_fish_01": "保留班长的关心，捕鱼数量和回营由操作体现",
  "serve_a_02": "保留小石恢复的反应，以动作结束递碗",
  "after_soup_01": "玩家看见老班长持碗离开并跟随",
  "after_soup_02": "环境声和侧后方视角代替解释路线",
  "march_03": "实地路线和已有操作提示足够",
  "march_04": "用老班长的步态、速度与身体姿态做伏笔",
  "found_elder_05": "拿起同一根竿的行动已经改变其意义",
  "silence_01": "保留沉默，让手部静止和风声承担这一刻",
  "archive_01": "移到可阅读的创作说明，结束镜头不再播放资料朗读",
  "archive_02": "保留在历史档案的文学/真人区分",
  "archive_03": "保留在可选历史档案",
  "archive_04": "保留在可选历史档案",
  "archive_05": "三关菜单保留1935/1936两个节点，移出结尾配音"
}
func lines_for(group:String)->Array:
	var rows=GROUPS.get("secret" if group=="secret_notice" else group,[])
	var result=[]
	for row in rows:
		if RETIRED.has(row.id):continue
		if group=="secret_notice" and row.id not in ["secret_01","secret_02"]:continue
		if group=="secret" and row.id in ["secret_01","secret_02"]:continue
		result.append(row.duplicate(true))
	return result
