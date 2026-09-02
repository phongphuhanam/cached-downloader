#!/bin/bash

fixuid

if [ -f $HOME/.oh-my-zsh/oh-my-zsh.sh ]; then
  echo "Oh My Zsh is already installed."
else
  echo "Installing Oh My Zsh."
  git clone https://github.com/ohmyzsh/ohmyzsh.git $HOME/.oh-my-zsh
  cp $HOME/.oh-my-zsh/templates/zshrc.zsh-template $HOME/.zshrc
fi

if [ -f $HOME/.config/nvim/init.lua ]; then
  echo "Nvim $NVIM_CONFIG_BRANCH config is installed"
else
  echo "Installing nvim $NVIM_CONFIG_BRANCH config"
  git clone -b $NVIM_CONFIG_BRANCH $NVIM_CONFIG_URL $HOME/.config/nvim
fi

if [ -f $HOME/.bashrc ]; then
  echo ".bashrc exists."
else
  echo "Copy .bashrc"
  cp /etc/skel/.bashrc $HOME/.bashrc
fi

exec "/bin/zsh"
