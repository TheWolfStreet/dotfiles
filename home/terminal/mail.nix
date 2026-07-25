{
  pkgs,
  config,
  gitEmail,
  gitName,
  ...
}: let
  pass_file = "${config.xdg.dataHome}/neomutt/gmail.pass.gpg";
  gpg = "${pkgs.gnupg}/bin/gpg";

  gmail_setup = pkgs.writeShellScriptBin "gmail-pass-setup" ''
    set -e
    mkdir -p "$(dirname "${pass_file}")"

    cat <<'INSTRUCTIONS'
    Gmail App Password setup for neomutt

    1. Turn on 2-Step Verification: https://myaccount.google.com/signinoptions/two-step-verification
    2. Create an App Password:       https://myaccount.google.com/apppasswords
       (name it "neomutt"; Google shows a 16-character password)
    3. Paste it below (spaces are fine, they get stripped).
    INSTRUCTIONS

    printf 'App password: '
    read -rs PW
    echo

    printf '%s' "$PW" | tr -d '[:space:]' | ${gpg} --encrypt --default-recipient-self -o "${pass_file}"
    echo "Saved (encrypted) to ${pass_file}. Run 'neomutt'."
  '';
in {
  home.packages = with pkgs; [
    neomutt
    isync
    msmtp
    notmuch
    w3m
    urlscan
    gmail_setup
  ];

  xdg.configFile."neomutt/neomuttrc".text = ''
    set realname = "${gitName}"
    set from = "${gitEmail}"

    set imap_user = "${gitEmail}"
    set imap_pass = "`${gpg} -q -d ${pass_file}`"
    set folder = "imaps://imap.gmail.com:993/"
    set spoolfile = "+INBOX"
    set postponed = "+[Gmail]/Drafts"
    set trash = "+[Gmail]/Trash"
    set record = "+[Gmail]/Sent Mail"

    set smtp_url = "smtps://${gitEmail}@smtp.gmail.com:465/"
    set smtp_pass = "`${gpg} -q -d ${pass_file}`"

    set header_cache = "${config.xdg.cacheHome}/neomutt/headers"
    set message_cachedir = "${config.xdg.cacheHome}/neomutt/messages"

    set ssl_force_tls = yes
    set ssl_starttls = yes

    set sidebar_visible = yes
    set sidebar_width = 30
    set sidebar_format = "%B%?F? [%F]?%* %?N?%N/?%S"
    set mail_check_stats

    set sort = threads
    set sort_aux = reverse-last-date-received
    set index_format = "%4C %Z %{%b %d} %-20.20L %s"

    set pager_stop = yes
    set pager_context = 3
    set tilde = yes
    auto_view text/html
    alternative_order text/plain text/enriched text/html

    set editor = "$EDITOR"
    set edit_headers = yes
    set fast_reply = yes
    set include = yes

    bind index,pager g noop
    bind index gg first-entry
    bind index G last-entry
    bind index,pager \Cd half-down
    bind index,pager \Cu half-up
    bind index,pager R group-reply
    bind index,pager @ compose-to-sender
    bind pager j next-line
    bind pager k previous-line
    bind attach,index,pager \CD next-page
    bind attach,index,pager \CU previous-page

    bind index,pager \Ck sidebar-prev
    bind index,pager \Cj sidebar-next
    bind index,pager \Co sidebar-open
    bind index,pager B sidebar-toggle-visible

    color normal color15 default
    color indicator color0 color3
    color status color15 color0
    color tree color6 default
    color signature color6 default
    color message color2 default
    color attachment color3 default
    color error color1 default
    color tilde color4 default
    color markers color1 default
    color quoted color2 default
    color quoted1 color6 default
    color quoted2 color3 default
    color hdrdefault color4 default
    color header color2 default "^From:"
    color header color6 default "^Subject:"
    color header color3 default "^Date:"
    color index color1 default "~D"
    color index color2 default "~N"
    color index color3 default "~F"

    mailboxes =INBOX =[Gmail]/Drafts =[Gmail]/Sent\ Mail =[Gmail]/Starred =[Gmail]/Trash
  '';

  xdg.dataFile."neomutt/.keep".text = "";
}
