{ myvars, ... }:
{
  programs.ssh = myvars.networking.ssh;

  users.users.${myvars.username} = {
    description = myvars.userfullname;
  };
}
