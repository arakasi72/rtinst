plugin.loadMainCSS();
plugin.loadLang();

plugin.onLangLoaded = function()
{
    var before = (theWebUI.systemInfo.rTorrent.started ? "add" : "settings");
    this.addButtonToToolbar("logoff", theUILang.logoff + " (" + plugin.me + ")", "theDialogManager.show('logoffDlg')", before);
    this.addSeparatorToToolbar(before);

    var options = "";
    for (var i = 0; i < plugin.users.length; i++)
        options += "<option value=\"" + plugin.users[i] + "\">" + plugin.users[i] + "</option>";

    var multi = false;
    var switchUser = "";
    if (options != "") {
        multi = true;
        switchUser = ""+
        "<div>"+
            "<label for=\"login.username\">" + theUILang.logoffUsername + ":</label> "+
            "<select id=\"login.username\">"+
                options+
            "</select>"+
        "</div>"+
        "<div>"+
            "<label for=\"login.password\">" + theUILang.logoffPassword + ":</label> <input type=\"password\" id=\"login.password\" class=\"Textbox\" /> <span id=\"logoffPassEmpty\"></span>"+
        "</div>"+
        (browser.isIE ? "" : "<div>" + theUILang.logoffNote + "</div>");
    }

    theDialogManager.make("logoffDlg", theUILang.logoff,
        "<div id=\"logoffDlg-content\">"+
            (multi ? theUILang.logoffSwitchPrompt + switchUser : theUILang.logoffPrompt)+
        "</div>"+
        "<div id=\"logoffDlg-buttons\" class=\"aright buttons-list\">"+
            (multi ? "<input type=\"button\" class=\"Button\" value=\"" + theUILang.logoffSwitch + "\" id=\"logoffSwitch\">" : "")+
            "<input type=\"button\" class=\"Button\" value=\"" + theUILang.logoff + "\" id=\"logoffComplete\">"+
            "<input type=\"button\" class=\"Button\" value=\"" + theUILang.Cancel + "\" id=\"logoffCancel\">"+
        "</div>",
    true);

    if (multi) {
        $("#logoffSwitch").click(function()
        {
            if ($($$("login.password")).val() == "") {
                $("#logoffPassEmpty").html(theUILang.logoffEmpty);
                return(false);
            }
            $("#logoffPassEmpty").html("");

            if (browser.isIE) {
                try {
                    var xmlhttp = (browser.isIE7up ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP"));
                    xmlhttp.open("GET", document.location.href, false, $($$("login.username")).val(), $($$("login.password")).val());
                    xmlhttp.onreadystatechange = function() { if (this.readyState == 4) theWebUI.reload(); };
                    xmlhttp.send(null);
                } catch (e) {}
            } else {
                if (document.location.protocol == "https:")
                    document.location = "https://" + $($$("login.username")).val() + ":" + $($$("login.password")).val() + "@" + document.location.href.substring(8);
                else
                    document.location = "http://" + $($$("login.username")).val() + ":" + $($$("login.password")).val() + "@" + document.location.href.substring(7);
            }
        });
    }

    $("#logoffComplete").click(function()
    {
        if (browser.isIE) {
            try {
                if (browser.isIE7up) {
                    document.execCommand("ClearAuthenticationCache");
                    theWebUI.reload();
                } else {
                    var xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
                    xmlhttp.open("GET", document.location.href, false, "logout", "");
                    xmlhttp.onreadystatechange = function() { if (this.readyState == 4) theWebUI.reload(); };
                    xmlhttp.send(null);
                }
            } catch (e) {}
        } else {
            if (document.location.protocol == "https:")
                document.location = "https://logoff@" + document.location.href.substring(8);
            else
                document.location = "http://logoff@" + document.location.href.substring(7);
        }
    });

    $("#logoffCancel").click(function()
    {
        theDialogManager.hide("logoffDlg");
        return(false);
    });
}

plugin.onRemove = function()
{
    theDialogManager.hide("logoffDlg");
    this.removeSeparatorFromToolbar(theWebUI.systemInfo.rTorrent.started ? "add" : "settings");
    this.removeButtonFromToolbar("logoff");
}
