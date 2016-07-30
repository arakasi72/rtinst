<?php
$me = getUser();
$users = array();

$dirs = scandir($rootPath . "/share/users/");
if ($dirs && count($dirs) > 0)
    foreach ($dirs as $dir)
        if ($dir[0] != "." && $dir != $me)
            $users[] = $dir;

$jResult .= "plugin.me = '" . $me . "';";
$jResult .= "plugin.users = " . json_encode($users) . ";";

$theSettings->registerPlugin("logoff");
?>
