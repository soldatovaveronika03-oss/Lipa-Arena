using UnityEngine;
public class MobaTower : MonoBehaviour
{
    public int Team; float cooldown;
    void Update(){
        cooldown-=Time.deltaTime;if(cooldown>0)return;
        MobaUnit target=null;float best=10;
        foreach(var u in GameBootstrap.I.Units){if(!u.IsAlive||u.Team==Team)continue;float d=Vector3.Distance(transform.position,u.transform.position);if(d<best){best=d;target=u;}}
        if(target!=null){target.TakeDamage(85,Team);cooldown=1.5f;}
    }
}
