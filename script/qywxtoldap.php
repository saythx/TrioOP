<?php
    /*
        brief : TrioPassPort基于企业微信提供统一身份认证
        author: liudun@trio.ai
        data : 2017-10-16
        modify : 2019-03-11
        modified_content : OA网络删除离职人员 
    */

// 设置时区
date_default_timezone_set('PRC');

//只允许内网访问 -- 暂时不生效
/*
$internal_IP = $_SERVER["REMOTE_ADDR"];
if (substr($internal_IP,0,4) != "10.0") {
    exit;
}
*/

// 重定向到企业微信二维码



// 获取access_token
$url = "https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=ww0a53985d3f265863&corpsecret=mQOaMlFSzZmYfm43_YKioRFjX4NOKXQTcZKCCcQvci8";
$access_token_body = json_decode(file_get_contents($url),true);
if ( $access_token_body['errcode'] == 0){
    $access_token = $access_token_body['access_token'];
}
$triolist = json_decode(file_get_contents("https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token=$access_token&department_id=1&fetch_child=1"),true);
print_r("https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token=$access_token&department_id=1&fetch_child=1");
echo "\n";
#print_r($triolist);
#exit;
//LDAP服务
$ds=ldap_connect("127.0.0.1","389");
$set = ldap_set_option ($ds, LDAP_OPT_REFERRALS, 0);
$set = ldap_set_option($ds, LDAP_OPT_PROTOCOL_VERSION, 3);
$r=ldap_bind($ds,"cn=root,dc=trio,dc=ai","TrioPassPort");    // root mode
$sr=ldap_search($ds, "dc=trio, dc=ai","(&(!(cn=TrioGuest))(objectclass=inetOrgPerson))");
$ori_userlist = ldap_get_entries($ds, $sr);

// print_r($ori_userlist);
// get former employee 
$ori_uid = array_map(function($item){
    return $item['cn'][0];
},$ori_userlist);
$cur_uid = array_map(function($item){
    return $item['userid']; 
},$triolist['userlist']);
$former_employee = array_diff($ori_uid,$cur_uid);
// $former_employee = array_diff($cur_uid,$ori_uid);
var_dump($former_employee);
$leave_num = count($former_employee);
if ($leave_num < 20) {
    foreach ($former_employee as $employee){
        $first = ldap_first_entry($ds,ldap_search($ds, "dc=trio,dc=ai", "(cn=$employee)"));
        $dn = ldap_get_dn($ds,$first);
        //$r = ldap_mod_replace($ds, $dn, array("employeeType" => 1));
        $r = ldap_delete($ds,$dn);
    }
}
foreach ($triolist['userlist'] as $item ){

    $info["uid"] = $item['userid'];
    $info["cn"] = $item['userid'];
    $info["sn"] = mb_substr($item['name'],0,1);
    $info["objectclass"] = "inetOrgPerson";
    $info["mail"] = $item['email'];
    $info["labeledURI"] = $item['avatar'];
    $info["displayName"] = $item['name'];
    $info["mobile"] = $item['mobile'];
    $info["departmentNumber"] = implode(",",$item['department']);
    $info['initials'] = $item['gender'];
    $info['employeeType'] = 0;
    
    $first = ldap_first_entry($ds,ldap_search($ds, "dc=trio,dc=ai", "(uid=".$item['userid'].")"));
    $userinfo = ldap_get_entries($ds,ldap_search($ds, "dc=trio,dc=ai", "(uid=".$item['userid'].")"));
    $dn = ldap_get_dn($ds,$first);
    if ($userinfo['count'] == 0) {
        $passwd = substr(md5($item['userid'].'triopassport'),0,6);
        $info["userPassword"] = $passwd;
        $r = ldap_add($ds, "uid={$info["uid"]},dc=trio,dc=ai", $info);
    } else {
        $info["userPassword"] = $userinfo[0]["userpassword"][0];
        $r = ldap_mod_replace($ds, $dn, $info);
    }   
}
/*
foreach ($triolist['userlist'] as $item ){
   ldap_delete($ds,"cn=".$item['userid'].",ou=1,dc=trio,dc=ai"); 
}
*/

?>
