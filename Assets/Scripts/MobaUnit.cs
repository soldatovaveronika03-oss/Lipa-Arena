using UnityEngine;

public class MobaUnit : MonoBehaviour
{
    public int Team, HeroType, Level=1, XP, MaxHealth=500;
    public float Health=500, MoveSpeed=5, AttackRange=3, Damage=55;
    public bool IsPlayer, IsAlive=true;
    public Vector3 MoveInput;
    float attackCd, skillCd, aiThink;
    Material bodyMat;
    string[] heroNames={"Kairon","Eliara","Rain"};
    public void Init(int team,int type,bool player,Material material){
        Team=team; HeroType=type; IsPlayer=player; bodyMat=material;
        MaxHealth=type==0?700:type==1?430:500; Health=MaxHealth; Damage=type==0?65:type==1?48:58;
        MoveSpeed=type==2?6:5; AttackRange=type==1?7:type==2?6:3;
        if(type==1) transform.localScale=new Vector3(.9f,1.1f,.9f);
        var r=GetComponent<Renderer>(); r.material=material;
        var ring=GameObject.CreatePrimitive(PrimitiveType.Cylinder); ring.name="Team ring"; ring.transform.SetParent(transform); ring.transform.localPosition=new Vector3(0,-.92f,0); ring.transform.localScale=new Vector3(1.5f,.05f,1.5f); ring.GetComponent<Renderer>().material=material; Destroy(ring.GetComponent<Collider>());
    }
    void Update(){
        if(!IsAlive)return; attackCd-=Time.deltaTime; skillCd-=Time.deltaTime;
        if(IsPlayer){MovePlayer();return;}
        aiThink-=Time.deltaTime;
        if(aiThink<=0){aiThink=Random.Range(.4f,.9f); ThinkAI();}
    }
    void MovePlayer(){
        Vector3 input=MoveInput;
        if(Input.GetKey(KeyCode.W))input.z=1; if(Input.GetKey(KeyCode.S))input.z=-1;
        if(Input.GetKey(KeyCode.A))input.x=-1; if(Input.GetKey(KeyCode.D))input.x=1;
        if(input.sqrMagnitude>.05f){transform.position+=input.normalized*MoveSpeed*Time.deltaTime; transform.forward=input.normalized;}
    }
    void ThinkAI(){
        MobaUnit target=null; float best=999;
        foreach(var u in GameBootstrap.I.Units){if(u==this||u.Team==Team||!u.IsAlive)continue;float d=Vector3.Distance(transform.position,u.transform.position);if(d<best){best=d;target=u;}}
        if(target!=null && best<AttackRange+1){if(attackCd<=0){target.TakeDamage(Damage,Team);attackCd=1.2f;}return;}
        Vector3 goal=Team==0?new Vector3(22,0,0):new Vector3(-22,0,0);
        if(target!=null && best<15)goal=target.transform.position;
        Vector3 dir=goal-transform.position;dir.y=0;
        if(dir.sqrMagnitude>1){transform.position+=dir.normalized*MoveSpeed*.45f*Time.deltaTime;transform.forward=dir.normalized;}
    }
    public void BasicAttack(){
        if(!IsAlive||attackCd>0)return; var t=FindTarget(AttackRange+1); if(t!=null){t.TakeDamage(Damage,Team);attackCd=.55f;}
    }
    public void CastSkill(int slot){
        if(!IsAlive||skillCd>0)return; float radius=slot==2?10:slot==1?6:4; float damage=Damage*(slot==2?3:slot==1?1.8f:1.3f);
        foreach(var u in GameBootstrap.I.Units)if(u.Team!=Team&&u.IsAlive&&Vector3.Distance(transform.position,u.transform.position)<=radius)u.TakeDamage(damage,Team);
        skillCd=slot==2?12:slot==1?7:4;
        var fx=GameObject.CreatePrimitive(PrimitiveType.Sphere);fx.transform.position=transform.position+Vector3.up;fx.transform.localScale=Vector3.one*radius*2;fx.GetComponent<Renderer>().material.color=HeroType==1?new Color(.5f,.2f,1,.4f):new Color(.2f,.8f,1,.4f);Destroy(fx.GetComponent<Collider>());Destroy(fx, .25f);
    }
    MobaUnit FindTarget(float range){MobaUnit t=null;float best=range;foreach(var u in GameBootstrap.I.Units){if(u.Team==Team||!u.IsAlive)continue;float d=Vector3.Distance(transform.position,u.transform.position);if(d<best){best=d;t=u;}}return t;}
    public void TakeDamage(float amount,int attackerTeam){
        if(!IsAlive)return;Health-=amount;if(Health<=0){Health=0;IsAlive=false;gameObject.SetActive(false);if(attackerTeam==0)GameBootstrap.I.TeamKills++;else GameBootstrap.I.EnemyKills++;if(attackerTeam==0&&GameBootstrap.I.Player!=null){GameBootstrap.I.Player.XP+=100;GameBootstrap.I.Gold+=120;if(GameBootstrap.I.Player.XP>=Level*250){Level++;MaxHealth+=80;Health=MaxHealth;Damage+=12;}}}
    }
}
