{...}: {
  programs.neomutt = {
    enable = true;
    sidebar.enable = true;
    vimKeys = true;
    sort = "reverse-threads";
    
    #binds = [
    #  { 
    #    map = "index"; 
    #    key = "gg";
    #    action = "first-entry"; 
    #  }
    #  {
    #    map = "index";
    #    key = "G";
    #    action = "last-entry";
    #  }
    #  {
    #    map = "index";
    #    key = "D";
    #    action = "delete-entry";
    #  }
    #  {
    #    map = "index";
    #    key = "D";
    #    action = "undelete-entry";
    #  }
    #];
  };
}
