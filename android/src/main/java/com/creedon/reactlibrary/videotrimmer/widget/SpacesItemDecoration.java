package com.creedon.reactlibrary.videotrimmer.widget;

import android.graphics.Rect;
import android.support.v7.widget.RecyclerView;
import android.view.View;
/**
 * _   _ _______   ________ _       _____   __
 * | \ | |_   _\ \ / /| ___ \ |     / _ \ \ / /
 * |  \| | | |  \ V / | |_/ / |    / /_\ \ V /
 * | . ` | | |  /   \ |  __/| |    |  _  |\ /
 * | |\  |_| |_/ /^\ \| |   | |____| | | || |
 * \_| \_/\___/\/   \/\_|   \_____/\_| |_/\_/
 * <p>
 * modified by jameskong on 12/2/2019.
 */
/**
 * Author: Jason.Chou
 * Email: who_know_me@163.com
 * Created: 2016年05月04日 11:27 AM
 * Description:
 */
public class SpacesItemDecoration extends RecyclerView.ItemDecoration{

  private int halfSpace;

  public SpacesItemDecoration(int space) {
    this.halfSpace = space / 2;
  }

  @Override
  public void getItemOffsets(Rect outRect, View view, RecyclerView parent, RecyclerView.State state) {

    if (parent.getPaddingLeft() != halfSpace) {
      parent.setPadding(halfSpace, halfSpace, halfSpace, halfSpace);
      parent.setClipToPadding(false);
    }

    outRect.top = halfSpace;
    outRect.bottom = halfSpace;
    outRect.left = halfSpace;
    outRect.right = halfSpace;
  }
}
