using System.Collections.Generic;
using UnityEngine;

public class GameBootstrap : MonoBehaviour
{
    public static GameBootstrap I;
    public readonly List<MobaUnit> Units = new();
    public readonly List<MobaTower> Towers = new();
    public MobaUnit Player;
    public int Gold = 500, TeamKills, EnemyKills;
    public string Status = "Выбери героя";

    Material matGrass, matLane, matBlue, matRed, matGold, matStone;
    Camera cam;
    float matchTime;
    bool started;

    void Awake() { I = this; }
    void Start() { BuildWorld(); ShowHeroSelect(); }
    void Update()
    {
        if (!started) return;
        matchTime += Time.deltaTime;
        if (Player != null && Player.IsAlive) FollowCamera();
    }

    void BuildWorld()
    {
        matGrass = Mat(new Color(.13f,.28f,.19f)); matLane = Mat(new Color(.42f,.39f,.32f));
        matBlue = Mat(new Color(.16f,.48f,.95f)); matRed = Mat(new Color(.9f,.2f,.18f));
        matGold = Mat(new Color(.95f,.68f,.16f)); matStone = Mat(new Color(.25f,.29f,.31f));
        var ground = GameObject.CreatePrimitive(PrimitiveType.Plane); ground.name="Verdant Rift"; ground.transform.localScale=new Vector3(8,1,8); ground.GetComponent<Renderer>().material=matGrass;
        BuildLane(new Vector3(-25,0,-22),new Vector3(25,0,22));
        BuildLane(new Vector3(-25,0,0),new Vector3(25,0,0));
        BuildLane(new Vector3(-25,0,22),new Vector3(25,0,-22));
        for(int i=0;i<22;i++){
            float x=Random.Range(-34,34), z=Random.Range(-30,30);
            if(Mathf.Abs(z)<5 || Mathf.Abs(x)<5) continue;
            var tree=GameObject.CreatePrimitive(PrimitiveType.Cylinder); tree.transform.position=new Vector3(x,1,z); tree.transform.localScale=new Vector3(1.2f,2.2f,1.2f); tree.GetComponent<Renderer>().material=matStone;
            var crown=GameObject.CreatePrimitive(PrimitiveType.Sphere); crown.transform.position=new Vector3(x,3.2f,z); crown.transform.localScale=Vector3.one*2.8f; crown.GetComponent<Renderer>().material=matGrass;
        }
        CreateBase(new Vector3(-32,0,0),0); CreateBase(new Vector3(32,0,0),1);
        CreateTower(new Vector3(-20,0,-17),0); CreateTower(new Vector3(-20,0,0),0); CreateTower(new Vector3(-20,0,17),0);
        CreateTower(new Vector3(20,0,-17),1); CreateTower(new Vector3(20,0,0),1); CreateTower(new Vector3(20,0,17),1);
        var light=new GameObject("Sun").AddComponent<Light>(); light.type=LightType.Directional; light.intensity=1.25f; light.transform.rotation=Quaternion.Euler(50,-30,0);
        var c=new GameObject("Main Camera"); cam=c.AddComponent<Camera>(); cam.orthographic=true; cam.orthographicSize=19; cam.transform.rotation=Quaternion.Euler(55,0,0); cam.transform.position=new Vector3(-5,30,-28); cam.tag="MainCamera";
    }
    void BuildLane(Vector3 a,Vector3 b){
        for(int i=0;i<30;i++){var p=Vector3.Lerp(a,b,i/29f); var q=GameObject.CreatePrimitive(PrimitiveType.Cube); q.name="Lane"; q.transform.position=p+Vector3.down*.04f; q.transform.localScale=new Vector3(2.5f,.12f,2.5f); q.GetComponent<Renderer>().material=matLane;}
    }
    void CreateBase(Vector3 p,int team){
        var g=GameObject.CreatePrimitive(PrimitiveType.Cylinder); g.name=team==0?"Blue Core":"Red Core"; g.transform.position=p+Vector3.up*1.4f; g.transform.localScale=new Vector3(5,1.4f,5); g.GetComponent<Renderer>().material=team==0?matBlue:matRed;
    }
    void CreateTower(Vector3 p,int team){
        var g=GameObject.CreatePrimitive(PrimitiveType.Cylinder); g.transform.position=p+Vector3.up*1.6f; g.transform.localScale=new Vector3(2.5f,1.6f,2.5f); g.GetComponent<Renderer>().material=team==0?matBlue:matRed;
        var t=g.AddComponent<MobaTower>(); t.Team=team; Towers.Add(t);
    }
    public void SelectHero(int type){
        if(started) return;
        started=true; Status="Сражение началось!";
        var names=new[]{"KAIRON — Боец","ELIARA — Маг","RAIN — Стрелок"};
        Player=SpawnUnit(new Vector3(-27,0,0),0,type,true,names[type]);
        for(int i=0;i<4;i++) SpawnUnit(new Vector3(-29+i*2,0,(i%2==0?5:-5)),0,i%3,false,"Союзник");
        for(int i=0;i<5;i++) SpawnUnit(new Vector3(25+i%2*2,0,(i-2)*4),1,i%3,false,"Противник");
    }
    MobaUnit SpawnUnit(Vector3 p,int team,int type,bool player,string label){
        var go=GameObject.CreatePrimitive(PrimitiveType.Capsule); go.name=label; go.transform.position=p+Vector3.up;
        var u=go.AddComponent<MobaUnit>(); u.Init(team,type,player,team==0?matBlue:matRed); Units.Add(u); return u;
    }
    void FollowCamera(){var target=Player.transform.position; cam.transform.position=Vector3.Lerp(cam.transform.position,new Vector3(target.x-2,32,target.z-25),Time.deltaTime*3); cam.transform.LookAt(target);}
    Material Mat(Color c){var m=new Material(Shader.Find("Standard")); m.color=c; return m;}
    void ShowHeroSelect(){Status="VEYRA: CLASH OF REALMS";}

    void OnGUI(){
        GUI.skin.label.fontSize=20; GUI.skin.button.fontSize=19;
        if(!started){
            GUI.Box(new Rect(Screen.width/2-190,Screen.height/2-150,380,300),"VEYRA: CLASH OF REALMS");
            GUI.Label(new Rect(Screen.width/2-150,Screen.height/2-95,300,35),"Выбери героя для матча 5 на 5");
            if(GUI.Button(new Rect(Screen.width/2-150,Screen.height/2-45,300,48),"KAIRON — Боец")) SelectHero(0);
            if(GUI.Button(new Rect(Screen.width/2-150,Screen.height/2+10,300,48),"ELIARA — Маг")) SelectHero(1);
            if(GUI.Button(new Rect(Screen.width/2-150,Screen.height/2+65,300,48),"RAIN — Стрелок")) SelectHero(2);
            return;
        }
        GUI.Box(new Rect(12,10,340,92),"VEYRA  |  5 VS 5");
        GUI.Label(new Rect(25,40,320,28),$"Уровень: {(Player?Player.Level:1)}   Золото: {Gold}");
        GUI.Label(new Rect(25,68,320,28),$"Убийства: {TeamKills} : {EnemyKills}");
        GUI.Box(new Rect(Screen.width-260,10,248,48),Status);
        if(Player==null)return;
        if(GUI.Button(new Rect(Screen.width-230,Screen.height-190,100,70),"АТАКА")) Player.BasicAttack();
        if(GUI.Button(new Rect(Screen.width-120,Screen.height-190,100,70),"НАВЫК 1")) Player.CastSkill(0);
        if(GUI.Button(new Rect(Screen.width-230,Screen.height-105,100,70),"НАВЫК 2")) Player.CastSkill(1);
        if(GUI.Button(new Rect(Screen.width-120,Screen.height-105,100,70),"УЛЬТА")) Player.CastSkill(2);
        if(GUI.Button(new Rect(18,Screen.height-120,150,90),"▲ ВПЕРЁД")) Player.MoveInput=new Vector3(0,0,1);
        if(GUI.Button(new Rect(18,Screen.height-55,150,45),"СТОП")) Player.MoveInput=Vector3.zero;
        GUI.Label(new Rect(20,112,250,30),$"HP: {Mathf.CeilToInt(Player.Health)}/{Player.MaxHealth}   XP: {Player.XP}");
    }
}
