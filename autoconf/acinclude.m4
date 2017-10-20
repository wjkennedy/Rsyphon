# This is adapted from the code I wrote for OpenHPI to do the same - Sean
#
# RS_CHECK_FAIL($LIBNAME,$PACKAGE_SUGGEST,$URL,$EXTRA)
#

AC_DEFUN([RS_CHECK_FAIL],
    [
    RS_MSG=`echo -e "- $1 not found!\n"`
    if test "x" != "x$4"; then
        RS_MSG=`echo -e "$RS_MSG\n- $4"`
    fi
    if test "x$2" != "x"; then
        RS_MSG=`echo -e "$RS_MSG\n- Try installing the $2 package\n"`
    fi
    if test "x$3" != "x"; then
        RS_MSG=`echo -e "$RS_MSG\n- or get the latest software from $3\n"`
    fi
    
    AC_MSG_ERROR(
!
************************************************************
$RS_MSG
************************************************************
)
    ]
)