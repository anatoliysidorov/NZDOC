Ext.onReady(function () {
  
    Ext.define('Override.STP.view.SetupSplash.Panel', {
        override: 'STP.view.SetupSplash.Panel',
        initComponent: function() {
            this.theme = 'blue';
            this.callParent(arguments);
        }
    });  
  
    Ext.define('override.BASE.ux.combo.ComboAssignTo', {
        override: 'BASE.ux.combo.ComboAssignTo',
        config: {
            listeners: {
                change: function (combo, newValue, oldValue, eOpts) {
                    var me = this,
                        selection = combo.getSelection();
                    //update data in viewmodel for workbasketId
                    if(newValue && newValue !== oldValue){
                        var currBind = me.bind? me.bind.WorkbasketId: null;

                        if(currBind && currBind.getValue() !== newValue){
                            currBind.setValue(newValue)
                        }
                    }
                }
            }
        }
    });
	
	//https://jira.appbase.com/browse/SAL-625
	
	Ext.define('Override.DCM.view.SearchCases.grid.ViewModel', {
        override: 'DCM.view.SearchCases.grid.ViewModel',
        config: {
                stores: {
                    storeSearchCases: {
                        model: 'DCM.model.Case',
                        proxy: EcxUtils5.Request.generateProxy('root_CUST_SearchCases', {
                            totalCount: 'TOTALCOUNT',
                            config: {startParam: 'FIRST', limitParam: 'LIMIT'}
                        }),
                        autoLoad: true,
                        sorters: {
                            property: 'ID',
                            direction: 'DESC'
                        },
                        remoteSort: true,
                        listeners: {
                            datachanged: 'onDataChanged',
                            beforeload: 'appendSearchParams'
                        },
                        pageSize: 100,
                        searchParams: {
							CASESYSTYPE_CODE: {bindTo: 'CASESYSTYPE_CODE_SEARCH'},
							CaseId: {fieldReference: 'txt_CASEID'},
							SUMMARY: {fieldReference: 'txt_SUMMARY'},
							// DESCRIPTION: {fieldReference: 'txt_DESCRIPTION'},
							CREATED_START: {fieldReference: 'date_CREATED_START'},
							CREATED_END: {fieldReference: 'date_CREATED_END'},
							WORKBASKETIDS: [{fieldReference: 'tag_WORKBASKETIDS'}, {bindTo: 'WORKBASKET_ID'}],
							PRIORITYIDS: {fieldReference: 'tag_PRIORITYIDS'},
							RESOLUTIONCODEIDS: {fieldReference: 'tag_RESOLUTIONCODEIDS'},
							TEAMIDS: {fieldReference: 'tag_TEAMIDS'},
							CASESYSTYPEIDS: {fieldReference: 'tag_CASESYSTYPEIDS'},
							CALCNAME: {fieldReference: 'txt_INVOLVEDPARTIESNAME'},
							CALCEMAIL: {fieldReference: 'txt_INVOLVEDPARTIESEMAIL'},
							CALCEXTSYSID: [{fieldReference: 'txt_INVOLVEDPARTIESEXTID'}, {bindTo: 'EXTSYSID'}],
							EXTERNALPARTYIDS: [{fieldReference: 'tag_CASEPARTYEXTERNAL'}, {bindTo: 'EXTERNALPARTY_ID'}],
							CASEWORKERIDS: [{fieldReference: 'tag_CASEWORKERIDS'}, {bindTo: 'CASEWORKER_ID'}],
							MILESTONEIDS: {fieldReference: 'tag_MILESTONEIDS'},
							CASESTATEIDS: {fieldReference: 'tag_CASESTATEIDS'},
							RISKIDS: {fieldReference: 'tag_RISKIDS'},
							URGENCYIDS: {fieldReference: 'tag_URGENCYIDS'}
						}
                    }
                }
            }
    }); 
	
	Ext.define('Override.DCM.view.MyCases.grid.ViewModel', {
        override: 'DCM.view.MyCases.grid.ViewModel',
        config: {
                stores: {
					storeMyWorkBaskets: {
						model: 'PPL.model.MyWorkBaskets',
						autoLoad: true,
						sorters: {
							property: 'ASC',
							direction: 'NAME'
						},
						remoteSort: true,
						listeners: {
							beforeload: 'appendSearchParams'
						},
						pageSize: 0
					},
					storeMyCases: {
						model: 'DCM.model.Case',
						proxy: EcxUtils5.Request.generateProxy('root_CUST_SearchMyCases'),
						autoLoad: true,
						sorters: {
							property: 'ID',
							direction: 'DESC'
						},
						remoteSort: true,
						listeners: {
							datachanged: 'onDataChanged',
							beforeload: 'appendSearchParams'
						},
						pageSize: 100,
						searchParams: {
							CASESYSTYPE_CODE: {bindTo: 'CASESYSTYPE_CODE_SEARCH'},
							CaseId: {fieldReference: 'txt_CASEID'},
							SUMMARY: {fieldReference: 'txt_SUMMARY'},
							DESCRIPTION: {fieldReference: 'txt_DESCRIPTION'},
							CREATED_START: {fieldReference: 'date_CREATED_START'},
							CREATED_END: {fieldReference: 'date_CREATED_END'},
							WORKBASKETIDS: {fieldReference: 'tag_WORKBASKETIDS'},
							PRIORITYIDS: {fieldReference: 'tag_PRIORITYIDS'},
							RESOLUTIONCODEIDS: {fieldReference: 'tag_RESOLUTIONCODEIDS'},
							TEAMIDS: {fieldReference: 'tag_TEAMIDS'},
							CASESYSTYPEIDS: {fieldReference: 'tag_CASESYSTYPEIDS'},
							CALCNAME: {fieldReference: 'txt_INVOLVEDPARTIESNAME'},
							CALCEMAIL: {fieldReference: 'txt_INVOLVEDPARTIESEMAIL'},
							CALCEXTSYSID: [{fieldReference: 'txt_INVOLVEDPARTIESEXTID'}, {bindTo: 'EXTSYSID'}],
							EXTERNALPARTYIDS: [{fieldReference: 'tag_CASEPARTYEXTERNAL'}, {bindTo: 'EXTERNALPARTY_ID'}],
							CASEWORKERIDS: [{fieldReference: 'tag_CASEWORKERIDS'}, {bindTo: 'CASEWORKER_ID'}],
							MILESTONEIDS: {fieldReference: 'tag_MILESTONEIDS'},
							CASESTATEIDS: {fieldReference: 'tag_CASESTATEIDS'},
							RISKIDS: {fieldReference: 'tag_RISKIDS'},
							URGENCYIDS: {fieldReference: 'tag_URGENCYIDS'}
						}
					}
				}
            }
    }); 
	
	Ext.define('Override.DCM.view.SearchCases.search.ViewModel', {
        override: 'DCM.view.SearchCases.search.ViewModel',
        config: { 
			stores: {
				storeCaseWorkers: {
					model: 'PPL.model.CaseWorker',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeResolutionCodes: {
					model: 'STP.model.ResolutionCode',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					listeners: {
						beforeload: 'appendSearchParams'
					},
					searchParams: {
						TYPECODE: 'CASE'
					},
					pageSize: 0
				},
				storeExternalParties: {
					model: 'PPL.model.ExternalParty',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeTeams: {
					model: 'PPL.model.Team',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeCaseTypes: {
					model: 'DCM.model.CaseType',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					searchParams: {
						PERMISSIONCODE: 'VIEW'
					},
					listeners: {
						beforeload: 'appendSearchParams'
					},
					pageSize: 0
				},
				storeMilestones: {
					model: 'DCM.model.ActiveMilestone',
					autoLoad: false,
					sorters: {
						property: 'CALCNAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeCaseStates: {
					model: 'STP.model.CaseState',
					autoLoad: false,
					sorters: {
						property: 'STATECONFIG_NAME',
						direction: 'ASC'
					},
					remoteSort: true,
					pageSize: 0
				},
				storeRisks: {
					fields: ['ID', 'NAME'],
					proxy: EcxUtils5.Request.generateProxy('root_DICT_getWords'),
					autoLoad: true,
					sorters: {
						property: 'ID',
						direction: 'DESC'
					},
					remoteSort: true,
					listeners: {
						datachanged: 'onDataChanged',
						beforeload: 'appendSearchParams'
					},
					searchParams: {
						CATEGORYPATH: 'RISK'
					}
				},
				storeUrgencies: {
					fields: ['ID', 'NAME'],
					proxy: EcxUtils5.Request.generateProxy('root_DICT_getWords'),
					autoLoad: true,
					sorters: {
						property: 'ID',
						direction: 'DESC'
					},
					remoteSort: true,
					listeners: {
						datachanged: 'onDataChanged',
						beforeload: 'appendSearchParams'
					},
					searchParams: {
						CATEGORYPATH: 'URGENCY'
					}
				}
			}
		}
    }); 
	
	Ext.define('Override.DCM.view.MyCases.search.ViewModel', {
        override: 'DCM.view.MyCases.search.ViewModel',
        config: { 
			stores: {
				storeCaseWorkers: {
					model: 'PPL.model.CaseWorker',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeResolutionCodes: {
					model: 'STP.model.ResolutionCode',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					listeners: {
						beforeload: 'appendSearchParams'
					},
					searchParams: {
						TYPECODE: 'CASE'
					},
					pageSize: 0
				},
				storeExternalParties: {
					model: 'PPL.model.ExternalParty',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeTeams: {
					model: 'PPL.model.Team',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeCaseTypes: {
					model: 'DCM.model.MyCaseType',
					autoLoad: false,
					sorters: {
						property: 'NAME',
						direction: 'ASC'
					},
					remoteSort: true,
					listeners: {
						beforeload: 'appendSearchParams'
					},
					pageSize: 0,
					searchParams: {
						CASESYSTYPE_CODE: {
							bindTo: 'CASESYSTYPE_CODE_SEARCH'
						}
					}
				},
				storeMilestones: {
					model: 'DCM.model.ActiveMilestone',
					autoLoad: false,
					sorters: {
						property: 'CALCNAME',
						direction: 'ASC'
					},
					pageSize: 0
				},
				storeCaseStates: {
					model: 'STP.model.CaseState',
					autoLoad: false,
					sorters: {
						property: 'STATECONFIG_NAME',
						direction: 'ASC'
					},
					remoteSort: true,
					pageSize: 0
				},
				storeRisks: {
					fields: ['ID', 'NAME'],
					proxy: EcxUtils5.Request.generateProxy('root_DICT_getWords'),
					autoLoad: true,
					sorters: {
						property: 'ID',
						direction: 'DESC'
					},
					remoteSort: true,
					listeners: {
						datachanged: 'onDataChanged',
						beforeload: 'appendSearchParams'
					},
					searchParams: {
						CATEGORYPATH: 'RISK'
					}
				},
				storeUrgencies: {
					fields: ['ID', 'NAME'],
					proxy: EcxUtils5.Request.generateProxy('root_DICT_getWords'),
					autoLoad: true,
					sorters: {
						property: 'ID',
						direction: 'DESC'
					},
					remoteSort: true,
					listeners: {
						datachanged: 'onDataChanged',
						beforeload: 'appendSearchParams'
					},
					searchParams: {
						CATEGORYPATH: 'URGENCY'
					}
				}
			}
		}
    }); 
	
	Ext.define('Override.DCM.view.SearchCases.grid.Panel', {
        override: 'DCM.view.SearchCases.grid.Panel',
        columns: [{
			width: 5,
			dataIndex: 'CASESYSTYPE_COLORCODE',
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				var casestateInfo = EcxUtils5.DCM.getCaseStateInfo({
					ISSTART: record.get('CASESTATE_ISSTART'),
					ISFINISH: record.get('CASESTATE_ISFINISH')
				});
				metaData.tdCls = ' ' + (casestateInfo.cls || '');
			}
		}, {
			text: 'ID',
			dataIndex: 'ID',
			sortable: true,
			hidden: true,
			width: 50
		}, {
			text: t('T', {context: 'caseType'}),
			dataIndex: 'CASESYSTYPE_NAME',
			width: 45,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				metaData.tdAttr = Ext.String.format('title="{0}"', record.get('CASESYSTYPE_NAME'));
				return EcxUtils5.DCM.renderCaseType(null, record.get('CASESYSTYPE_COLORCODE'), record.get('CASESYSTYPE_ICONCODE'));
			}
		}, {
			text: t('Case Type'),
			dataIndex: 'CASESYSTYPE_NAME',
			width: 200,
			sortable: true,
			hidden: true
		}, {
			text: t('Case ID'),
			dataIndex: 'CASEID',
			width: 140,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				var c = view.lookupController(),
					isRenderLink = (record.get('PERM_CASETYPE_DETAIL') !== undefined) ? record.get('PERM_CASETYPE_DETAIL') : true;
				return (isRenderLink) ? c.renderDetailLink(value, metaData, record) : value;
			}
		}, {
			text: t('Risk'),
			dataIndex: 'RISK',
			width: 200,
			sortable: true
		}, {
			text: t('Urgency'),
			dataIndex: 'URGENCY',
			width: 200,
			sortable: true
		}, {
			text: t('Summary'),
			dataIndex: 'SUMMARY',
			flex: 1,
			sortable: true,
			minWidth: 400
		}, {
			dataIndex: 'GOALSLADURATION',
			text: t('Goal'),
			width: 160,
			hidden: false,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				//only show SLA if case is not closed
				if (record.get('CASESTATE_ISFINISH')) {
					return '';
				}
				var ms,
					slaDuration = '';
				//calculate duration
				if (record.get('GOALSLADURATION') != null) {
					ms = -1 * record.get('GOALSLADURATION');
					slaDuration = EcxUtils5.DCM.renderderSLA(ms);
				}
				return slaDuration;
			}
		}, {
			dataIndex: 'DLINESLADURATION',
			text: t('Deadline'),
			width: 160,
			hidden: false,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				//only show SLA if case is not closed
				if (record.get('CASESTATE_ISFINISH')) {
					return '';
				}
				var ms,
					slaDuration = '';
				//calculate duration
				if (record.get('DLINESLADURATION') != null) {
					ms = -1 * record.get('DLINESLADURATION');
					slaDuration = EcxUtils5.DCM.renderderSLA(ms);
				}
				return slaDuration;
			}
		}, {
			text: t('Case Owner'),
			dataIndex: 'WORKBASKET_NAME',
			width: 200,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				return EcxUtils5.DCM.renderWorkBasket(record.get('WORKBASKET_NAME'), record.get('WORKBASKET_TYPE_CODE'));
			},
			bind: {
				hidden: '{isHideCaseOwnerField}'
			}
		}, {
			text: t('P', {context: 'priority'}),
			dataIndex: 'PRIORITY_VALUE',
			width: 40,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, r) {
				metaData.tdAttr = Ext.String.format('title="{0} ({1})"', record.get('PRIORITY_NAME'), record.get('PRIORITY_VALUE'));
				return EcxUtils5.DCM.renderPriority(record.get('PRIORITY_VALUE'));
			}
		}, {
			text: t('State'),
			dataIndex: 'CASESTATE_NAME',
			width: 125,
			hidden:true,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				var config = {
					ISSTART: record.get('CASESTATE_ISSTART'),
					ISFINISH: record.get('CASESTATE_ISFINISH')
				};
				var casestate = EcxUtils5.DCM.renderCaseState(value, config);
				metaData.tdCls += ' ' + EcxUtils5.DCM.getCaseStateInfo(config).cls + '-bgl';
				return casestate;
			}
		}, {
			text: t('Milestone'),
			dataIndex: 'MS_STATENAME',
			width: 125,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				var config = {
					ISSTART: record.get('CASESTATE_ISSTART'),
					ISFINISH: record.get('CASESTATE_ISFINISH')
				};
				var casestate = EcxUtils5.DCM.renderCaseState(value, config);
				metaData.tdCls += ' ' + EcxUtils5.DCM.getCaseStateInfo(config).cls + '-bgl';
				return casestate;
			}
		},  {
			text: t('Resolution'),
			dataIndex: 'RESOLUTIONCODE_NAME',
			width: 150,
			sortable: true,
			renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
				return EcxUtils5.DCM.renderResCode(
					record.get('RESOLUTIONCODE_NAME'),
					record.get('RESOLUTIONCODE_THEME'),
					record.get('RESOLUTIONCODE_ICON'),
					metaData);
			}
		},
			{
				xtype: 'ecx-datecolumn',
				baseField: 'CREATED'
			},
			{
				xtype: 'ecx-namecolumn',
				baseField: 'CREATED'
			},
			{
				xtype: 'ecx-datecolumn',
				baseField: 'MODIFIED',
				hidden: true
			},
			{
				xtype: 'ecx-namecolumn',
				baseField: 'MODIFIED',
				hidden: true
			}
		]
    }); 
	
	Ext.define('Override.DCM.view.MyCases.grid.Panel', {
        override: 'DCM.view.MyCases.grid.Panel',
        columns: [
			//columns
			{
				width: 5,
				dataIndex: 'CASESYSTYPE_COLORCODE',
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					var casestateInfo = EcxUtils5.DCM.getCaseStateInfo({
						ISSTART: record.get('CASESTATE_ISSTART'),
						// ISASSIGN: record.get('CASESTATE_ISASSIGN'),
						// ISFIX: record.get('CASESTATE_ISFIX'),
						// ISRESOLVE: record.get('CASESTATE_ISRESOLVE'),
						ISFINISH: record.get('CASESTATE_ISFINISH')
					});

					metaData.tdCls = ' ' + (casestateInfo.cls || '');
				}
			}, {
				text: 'ID',
				dataIndex: 'ID',
				sortable: true,
				hidden: true,
				width: 50
			}, {
				text: t('T', {context: 'caseType'}),
				dataIndex: 'CASESYSTYPE_NAME',
				width: 50,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					metaData.tdAttr = Ext.String.format('title="{0}"', record.get('CASESYSTYPE_NAME'));
					return EcxUtils5.DCM.renderCaseType(null, record.get('CASESYSTYPE_COLORCODE'), record.get('CASESYSTYPE_ICONCODE'));
				}
			}, {
				text: t('Case Type'),
				dataIndex: 'CASESYSTYPE_NAME',
				width: 200,
				sortable: true,
				hidden: true
			}, {
				text: t('Case ID'),
				dataIndex: 'CASEID',
				width: 140,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					var c = view.lookupController(),
						isRenderLink = (record.get('PERM_CASETYPE_DETAIL') !== undefined) ? record.get('PERM_CASETYPE_DETAIL') : true;
					return (isRenderLink) ? c.renderDetailLink(value, metaData, record) : value;
				}
			}, {
				text: t('Risk'),
				dataIndex: 'RISK',
				width: 200,
				sortable: true
			}, {
				text: t('Urgency'),
				dataIndex: 'URGENCY',
				width: 200,
				sortable: true
			}, {
				text: t('Summary'),
				dataIndex: 'SUMMARY',
				flex: 1,
				sortable: true,
				minWidth: 400
			}, {
				dataIndex: 'GOALSLADURATION',
				text: t('Goal'),
				width: 160,
				hidden: false,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					//only show SLA if case is not closed
					if (record.get('CASESTATE_ISFINISH')) {
						return '';
					}
					var ms,
						slaDuration = '';
					//calculate duration
					if (record.get('GOALSLADURATION') != null) {
						ms = -1 * record.get('GOALSLADURATION');
						slaDuration = EcxUtils5.DCM.renderderSLA(ms);
					}
					return slaDuration;
				}
			}, {
				dataIndex: 'DLINESLADURATION',
				text: t('Deadline'),
				width: 160,
				hidden: false,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					//only show SLA if case is not closed
					if (record.get('CASESTATE_ISFINISH')) {
						return '';
					}
					var ms,
						slaDuration = '';
					//calculate duration
					if (record.get('DLINESLADURATION') != null) {
						ms = -1 * record.get('DLINESLADURATION');
						slaDuration = EcxUtils5.DCM.renderderSLA(ms);
					}
					return slaDuration;
				}
			}, {
				text: t('Case Owner'),
				dataIndex: 'WORKBASKET_NAME',
				width: 200,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					return EcxUtils5.DCM.renderWorkBasket(record.get('WORKBASKET_NAME'), record.get('WORKBASKET_TYPE_CODE'));
				}
			}, {
				text: t('P', {context: 'priority'}),
				dataIndex: 'PRIORITY_VALUE',
				width: 40,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, r) {
					metaData.tdAttr = Ext.String.format('title="{0} ({1})"', record.get('PRIORITY_NAME'), record.get('PRIORITY_VALUE'));
					return EcxUtils5.DCM.renderPriority(record.get('PRIORITY_VALUE'));
				}
			}, {
				text: t('State'),
				dataIndex: 'CASESTATE_NAME',
				width: 125,
				hidden:true,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					var config = {
						ISSTART: record.get('CASESTATE_ISSTART'),
						ISFINISH: record.get('CASESTATE_ISFINISH')
					};
					var casestate = EcxUtils5.DCM.renderCaseState(record.get('CASESTATE_NAME'), config);
					metaData.tdCls += ' ' + EcxUtils5.DCM.getCaseStateInfo(config).cls + '-bgl';
					return casestate;
				}
			}, {
				text: t('Milestone'),
				dataIndex: 'MS_STATENAME',
				width: 125,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					var config = {
						ISSTART: record.get('CASESTATE_ISSTART'),
						ISFINISH: record.get('CASESTATE_ISFINISH')
					};
					var casestate = EcxUtils5.DCM.renderCaseState(value, config);
					metaData.tdCls += ' ' + EcxUtils5.DCM.getCaseStateInfo(config).cls + '-bgl';
					return casestate;
				}
			}, {
				text: t('Resolution'),
				dataIndex: 'RESOLUTIONCODE_NAME',
				width: 150,
				sortable: true,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					return EcxUtils5.DCM.renderResCode(
						record.get('RESOLUTIONCODE_NAME'),
						record.get('RESOLUTIONCODE_THEME'),
						record.get('RESOLUTIONCODE_ICON'),
						metaData);
				}
			}, {
				xtype: 'ecx-datecolumn',
				baseField: 'CREATED'
			},
			{
				xtype: 'ecx-namecolumn',
				baseField: 'CREATED'
			},
			{
				xtype: 'ecx-datecolumn',
				baseField: 'MODIFIED'
			},
			{
				xtype: 'ecx-namecolumn',
				baseField: 'MODIFIED'
			}	
		]
    });
	
	Ext.define('Override.DCM.view.SearchCases.search.Panel', {
        override: 'DCM.view.SearchCases.search.Panel',
        items: [{
			xtype: 'textfield',
			reference: 'txt_CASEID',
			maxLength: 255,
			enforceMaxLength: true,
			fieldLabel: t('Case ID')
		}, {
			xtype: 'textfield',
			reference: 'txt_SUMMARY',
			maxLength: 255,
			enforceMaxLength: true,
			fieldLabel: t('Summary')
		}, {
			xtype: 'fieldcontainer',
			layout: 'hbox',
			fieldLabel: t('Created Date'),
			items: [{
				xtype: 'datefield',
				reference: 'date_CREATED_START',
				flex: 1
			}, {
				xtype: 'label',
				text: t('to', {
					context: 'date'
				}),
				width: 25,
				style: 'padding-left:6px; padding-top:2px'
			}, {
				xtype: 'datefield',
				reference: 'date_CREATED_END',
				flex: 1
			}]
		}, {
			xtype: 'ecx-tagfieldPriority',
			reference: 'tag_PRIORITYIDS',
			queryMode: 'remote',
			storeConfig: {
				autoLoad: false
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Resolution Code'),
			reference: 'tag_RESOLUTIONCODEIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeResolutionCodes}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Teams'),
			reference: 'tag_TEAMIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeTeams}'
			}
		},{
			xtype: 'ecx-tagfieldWorkBasket',
			fieldLabel: t('Case Owner'),
			reference: 'tag_WORKBASKETIDS',
			bind: {
				hidden: '{isHideCaseOwnerField}'
			}
		},{
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Case Type'),
			reference: 'tag_CASESYSTYPEIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			minChars: 2, //default is 4
			queryParam: 'PSEARCH',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeCaseTypes}'
			},
			listeners: {
				change: 'onCaseSysTypeChange'
			},
			triggers: {
				clear: {
					handler: function () {
						var me = this,
							controller = me.lookupController();
						me.reset();
						controller.onCaseSysTypeChange(me, null);
					}
				}
			}
		}, {
			xtype: 'ecx-tagfieldgrid',
			reference: 'tag_MILESTONEIDS',
			fieldLabel: t('Milestone'),
			displayField: 'CALCNAME',
			valueField: 'IDS',
			queryMode: 'remote',
			lastQuery: '',
			bind: {
				store: '{storeMilestones}'
			},
			columns: [{
				text: t('T', {context: 'caseType'}),
				dataIndex: 'CASESYSTYPE_NAME',
				width: 40,
				sortable: false,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					metaData.tdAttr = Ext.String.format('title="{0}"', record.get('CASESYSTYPE_NAME'));
					return EcxUtils5.DCM.renderCaseType(null, record.get('CASESYSTYPE_COLORCODE'), record.get('CASESYSTYPE_ICONCODE'));
				}
			}, {
				text: t('Case Type'),
				dataIndex: 'CASESYSTYPE_NAME',
				sortable: false,
				width: 200
			}, {
				text: t('Milestone'),
				dataIndex: 'NAME',
				sortable: false,
				width: 250
			}]
		}, {
			xtype: 'ecx-tagfieldgrid',
			reference: 'tag_CASESTATEIDS',
			fieldLabel: t('Case State'),
			displayField: 'CALCNAME',
			valueField: 'ID',
			queryMode: 'remote',
			lastQuery: '',
			bind: {
				store: '{storeCaseStates}'
			},
			columns: [{
				text: t('State Diagram'),
				dataIndex: 'STATECONFIG_NAME',
				width: 250
			}, {
				text: t('Name'),
				dataIndex: 'NAME',
				width: 250
			}]
		}, {
			xtype: 'textfield',
			reference: 'txt_INVOLVEDPARTIESNAME',
			fieldLabel: t('Involved Parties Name')
		}, {
			xtype: 'textfield',
			reference: 'txt_INVOLVEDPARTIESEMAIL',
			fieldLabel: t('Involved Parties Email')
		}, {
			xtype: 'textfield',
			reference: 'txt_INVOLVEDPARTIESEXTID',
			fieldLabel: t('Involved Parties Ext ID')
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Case Party External'),
			reference: 'tag_CASEPARTYEXTERNAL',
			displayField: 'NAME',
			valueField: 'ID',
			minChars: 2, //default is 4
			queryParam: 'PSEARCH',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeExternalParties}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Case Party Internal'),
			reference: 'tag_CASEWORKERIDS',
			displayField: 'NAME',
			valueField: 'ID',
			minChars: 2, //default is 4
			queryParam: 'PSEARCH',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeCaseWorkers}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Risk'),
			reference: 'tag_RISKIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeRisks}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Urgency'),
			reference: 'tag_URGENCYIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeUrgencies}'
			}
		}]
    });
	
	Ext.define('Override.DCM.view.MyCases.search.Panel', {
        override: 'DCM.view.MyCases.search.Panel',
        items: [{
			xtype: 'textfield',
			reference: 'txt_CASEID',
			fieldLabel: t('Case ID')
		}, {
			xtype: 'textfield',
			reference: 'txt_SUMMARY',
			fieldLabel: t('Summary')
		}, {
			xtype: 'textfield',
			reference: 'txt_DESCRIPTION',
			hidden: true,
			fieldLabel: t('Description')
		}, {
			xtype: 'fieldcontainer',
			layout: 'hbox',
			fieldLabel: t('Created Date'),
			items: [{
				xtype: 'datefield',
				reference: 'date_CREATED_START',
				flex: 1
			}, {
				xtype: 'label',
				text: t('to', {context: 'date'}),
				width: 25,
				style: 'padding-left:6px; padding-top:2px'
			}, {
				xtype: 'datefield',
				reference: 'date_CREATED_END',
				flex: 1
			}
			]
		}, {
			xtype: 'ecx-tagfieldPriority',
			reference: 'tag_PRIORITYIDS',
			queryMode: 'remote',
			storeConfig: {
				autoLoad: false
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Resolution Code'),
			reference: 'tag_RESOLUTIONCODEIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeResolutionCodes}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Teams'),
			reference: 'tag_TEAMIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeTeams}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Case Type'),
			reference: 'tag_CASESYSTYPEIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeCaseTypes}'
			},
			listeners: {
				change: 'onCaseSysTypeChange'
			},
			triggers: {
				clear: {
					handler: function () {
						var me = this,
							controller = me.lookupController();
						me.reset();
						controller.onCaseSysTypeChange(me, null);
					}
				}
			}
		}, {
			xtype: 'ecx-tagfieldgrid',
			reference: 'tag_MILESTONEIDS',
			fieldLabel: t('Milestone'),
			displayField: 'CALCNAME',
			valueField: 'IDS',
			queryMode: 'remote',
			lastQuery: '',
			bind: {
				store: '{storeMilestones}'
			},
			columns: [{
				text: t('T', {context: 'caseType'}),
				dataIndex: 'CASESYSTYPE_NAME',
				width: 40,
				sortable: false,
				renderer: function (value, metaData, record, rowIndex, colIndex, store, view, returnString) {
					metaData.tdAttr = Ext.String.format('title="{0}"', record.get('CASESYSTYPE_NAME'));
					return EcxUtils5.DCM.renderCaseType(null, record.get('CASESYSTYPE_COLORCODE'), record.get('CASESYSTYPE_ICONCODE'));
				}
			}, {
				text: t('Case Type'),
				dataIndex: 'CASESYSTYPE_NAME',
				sortable: false,
				width: 200
			}, {
				text: t('Milestone'),
				dataIndex: 'NAME',
				sortable: false,
				width: 250
			}]
		}, {
			xtype: 'ecx-tagfieldgrid',
			reference: 'tag_CASESTATEIDS',
			fieldLabel: t('Case State'),
			displayField: 'CALCNAME',
			valueField: 'ID',
			queryMode: 'remote',
			lastQuery: '',
			bind: {
				store: '{storeCaseStates}'
			},
			columns: [{
				text: t('Milestone'),
				dataIndex: 'STATECONFIG_NAME',
				width: 250
			}, {
				text: t('Name'),
				dataIndex: 'NAME',
				width: 250
			}]
		}, {
			xtype: 'textfield',
			reference: 'txt_INVOLVEDPARTIESNAME',
			fieldLabel: t('Involved Parties Name')
		}, {
			xtype: 'textfield',
			reference: 'txt_INVOLVEDPARTIESEMAIL',
			fieldLabel: t('Involved Parties Email')
		}, {
			xtype: 'textfield',
			reference: 'txt_INVOLVEDPARTIESEXTID',
			fieldLabel: t('Involved Parties Ext ID')
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Case Party External'),
			reference: 'tag_CASEPARTYEXTERNAL',
			displayField: 'NAME',
			valueField: 'ID',
			minChars: 2, //default is 4
			queryParam: 'PSEARCH',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeExternalParties}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Case Party Internal'),
			reference: 'tag_CASEWORKERIDS',
			displayField: 'NAME',
			valueField: 'ID',
			minChars: 2, //default is 4
			queryParam: 'PSEARCH',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeCaseWorkers}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Risk'),
			reference: 'tag_RISKIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeRisks}'
			}
		}, {
			xtype: 'ecx-tagfieldisdeleted',
			fieldLabel: t('Urgency'),
			reference: 'tag_URGENCYIDS',
			displayField: 'NAME',
			valueField: 'ID',
			queryMode: 'remote',
			filterPickList: true,
			delimiter: ',',
			bind: {
				store: '{storeUrgencies}'
			}
		}]
    }); 
	
	

}, null, {
    dom: true
});
