# prompt style and colors based on Steve Losh's Prose theme:
# http://github.com/sjl/oh-my-zsh/blob/master/themes/prose.zsh-theme
#
# vcs_info modifications from Bart Trojanowski's zsh prompt:
# http://www.jukie.net/bart/blog/pimping-out-zsh-prompt
#
# git untracked files modification from Brian Carper:
# http://briancarper.net/blog/570/git-info-in-your-zsh-prompt

export VIRTUAL_ENV_DISABLE_PROMPT=1

function virtualenv_info {
    [ $VIRTUAL_ENV ] && echo '('%F{blue}`basename $VIRTUAL_ENV`%f') '
}
PR_GIT_UPDATE=1

setopt prompt_subst

autoload -U add-zsh-hook
autoload -Uz vcs_info

#use extended color palette if available
if [[ $terminfo[colors] -ge 256 ]]; then
    turquoise="%F{81}"
    orange="%F{166}"
    purple="%F{135}"
    hotpink="%F{161}"
    limegreen="%F{118}"
else
    turquoise="%F{cyan}"
    orange="%F{yellow}"
    purple="%F{magenta}"
    hotpink="%F{red}"
    limegreen="%F{green}"
fi

# enable VCS systems you use
zstyle ':vcs_info:*' enable git svn

# check-for-changes can be really slow.
# you should disable it, if you work with large repositories
zstyle ':vcs_info:*:prompt:*' check-for-changes true

# set formats
# %b - branchname
# %u - unstagedstr (see below)
# %c - stagedstr (see below)
# %a - action (e.g. rebase-i)
# %R - repository path
# %S - path in the repository
PR_RST="%f"
FMT_BRANCH="(%{$turquoise%}%b%u%c${PR_RST})"
FMT_ACTION="(%{$limegreen%}%a${PR_RST})"
FMT_UNSTAGED="%{$orange%}●"
FMT_STAGED="%{$limegreen%}●"

zstyle ':vcs_info:*:prompt:*' unstagedstr   "${FMT_UNSTAGED}"
zstyle ':vcs_info:*:prompt:*' stagedstr     "${FMT_STAGED}"
zstyle ':vcs_info:*:prompt:*' actionformats "${FMT_BRANCH}${FMT_ACTION}"
zstyle ':vcs_info:*:prompt:*' formats       "${FMT_BRANCH}"
zstyle ':vcs_info:*:prompt:*' nvcsformats   ""


function steeef_preexec {
    case "$(history $HISTCMD)" in
        *git*)
            PR_GIT_UPDATE=1
            ;;
        *svn*)
            PR_GIT_UPDATE=1
            ;;
    esac
}
add-zsh-hook preexec steeef_preexec

function steeef_chpwd {
    PR_GIT_UPDATE=1
}
add-zsh-hook chpwd steeef_chpwd

function terraform_workspace {
    FILE=.terraform/environment

    if [ -f $FILE ]; then
        tfenv=$(cat .terraform/environment 2> /dev/null | sed "s/\(.*\)/\1/")%{$reset_color%}
        echo "(%F{161}$tfenv%f)"
    fi
}

function steeef_precmd {
    if [[ -n "$PR_GIT_UPDATE" ]] ; then
        # check for untracked files or updated submodules, since vcs_info doesn't
        if git ls-files --other --exclude-standard 2> /dev/null | grep -q "."; then
            PR_GIT_UPDATE=1
            FMT_BRANCH="(%{$turquoise%}%b%u%c%{$hotpink%}●${PR_RST}) (%F{068}$(git_prompt_short_sha)%f)"
        else
            FMT_BRANCH="(%{$turquoise%}%b%u%c${PR_RST}) (%F{068}$(git_prompt_short_sha)%f)"
        fi
        zstyle ':vcs_info:*:prompt:*' formats "${FMT_BRANCH} "

        vcs_info 'prompt'
        PR_GIT_UPDATE=
    fi
}
add-zsh-hook precmd steeef_precmd

function prompt-length() {
  emulate -L zsh
  local COLUMNS=${2:-$COLUMNS}
  local -i x y=$#1 m
  if (( y )); then
    while (( ${${(%):-$1%$y(l.1.0)}[-1]} )); do
      x=y
      (( y *= 2 ));
    done
    local xy
    while (( y > x + 1 )); do
      m=$(( x + (y - x) / 2 ))
      typeset ${${(%):-$1%$m(l.x.y)}[-1]}=$m
    done
  fi
  echo $x
}

function fill-line() {
  emulate -L zsh
  local left_len=$(prompt-length $1)
  local right_len=$(prompt-length $2 9999)
  local pad_len=$((COLUMNS - left_len - right_len - ${ZLE_RPROMPT_INDENT:-1}))
  if (( pad_len < 1 )); then
    # Not enough space for the right part. Drop it.
    echo -E - ${1}
  else
    local pad=${(pl.$pad_len.. .)}  # pad_len spaces
    echo -E - ${1}${pad}${2}
  fi
}

function preexec() {
  unset timer
  timer=${SECONDS}
}

function precmd() {
  if [ $timer ]; then
    elapsed=$(($SECONDS - $timer))
  fi
}

function show_time() {
  num=$1
  min=0
  hour=0
  day=0
  if ((num>59)); then
    ((sec=num%60))
    ((num=num/60))
    if ((num>59));then
      ((min=num%60))
      ((num=num/60))
      if ((num>23));then
        ((hour=num%24))
        ((day=num/24))
      else
        ((hour=num))
      fi
    else
    ((min=num))
    fi
  else
    ((sec=num))
  fi

  if (( day > 0 )); then
    echo "$day"d "$hour"h "$min"m "$sec"s
  else
    if (( hour > 0)); then
      echo "$hour"h "$min"m "$sec"s
    else
      if (( min > 0)); then
        echo "$min"m "$sec"s
      else
        echo "$sec"s
      fi
    fi
  fi

}

PROMPT=$'╭─%{$purple%}%n${PR_RST}@%{$orange%}%m${PR_RST} %{$limegreen%}%~${PR_RST} $vcs_info_msg_0_$(virtualenv_info)$(terraform_workspace)\n╰─%B$%b '
PROMPT=$'$(fill-line "╭─%{$purple%}%n${PR_RST}@%{$orange%}%m${PR_RST} %{$limegreen%}%~${PR_RST} $vcs_info_msg_0_$(virtualenv_info)$(terraform_workspace) " "  %{$limegreen%}$(show_time $elapsed)%f")\n╰─%B$%b ' #with date at the right
RPROMPT='%F{60}[%D{%a %b %d %H:%M:%S}]%f' # text to stay on the right os cursor
