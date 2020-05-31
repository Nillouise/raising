// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'item.dart';
import 'page.dart';

import 'package:raising/channel/Smb.dart';

var logger = Logger();

const catalogLength = 200;

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<ItemPage> fetchPage(int startingIndex) async {
//  Smb.pushConfig("[C]","192.168.1.100", "wd", "", "maho", "maho", "[C]", "*");
  Smb.pushConfig("[C]","DESKTOP-7MSGQCD", "share", "", "Nillouise", "maho", "", "*");

  List list = await Smb.getConfig("[C]")
      .smbList();
  if (startingIndex > list.length) {
    return ItemPage(
      items: [],
      startingIndex: startingIndex,
      hasNext: false,
    );
  }
  int curPageCount = min(itemsPerPage, list.length - startingIndex);

  // The page of items is generated here.
  return ItemPage(
    items: List.generate(
        curPageCount,
        (index) => Item(
              color: Colors.primaries[index % Colors.primaries.length],
              name: list[startingIndex + index],
              price: 50 + (index * 42) % 200,
            )),
    startingIndex: startingIndex,
    // Returns `false` if we've reached the [catalogLength].
    hasNext: startingIndex + curPageCount < list.length,
  );
}
